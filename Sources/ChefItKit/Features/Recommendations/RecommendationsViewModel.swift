import Combine
import Foundation

/// Drives the recommendations screen. Runs the planner → search → matcher
/// pipeline with auto-included staples (salt, pepper, water, oils) so real
/// recipes can hit "Ready" status. Staples are toggleable per-session.
@MainActor
public final class RecommendationsViewModel: ObservableObject {
    @Published public private(set) var readyMatches: [RecipeMatch] = []
    @Published public private(set) var almostMatches: [RecipeMatch] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var ingredientCount: Int = 0
    @Published public var excludedStaples: Set<String> = []

    /// Pantry items so common we assume everyone has them. Users can toggle
    /// any of these off via `toggleStaple(_:)` if they're actually out.
    public static let defaultStaples: [String] = [
        "salt", "pepper", "water", "olive oil", "vegetable oil", "butter"
    ]

    public var activeStaples: [String] {
        Self.defaultStaples.filter { !excludedStaples.contains($0) }
    }

    private let ingredientStore: IngredientStore
    private let planner: RecipeDiscoveryPlanner
    private let matcher: RecipeMatcher
    private let searchService: any RecipeSearchService
    private let normalizer: IngredientNormalizer
    private var ingredientSink: AnyCancellable?

    private static let minCoverageToShow = 0.30
    private static let maxAlmostToShow = 10

    public init(
        ingredientStore: IngredientStore,
        searchService: (any RecipeSearchService)? = nil,
        planner: RecipeDiscoveryPlanner = RecipeDiscoveryPlanner(),
        matcher: RecipeMatcher = RecipeMatcher(almostThreshold: 15),
        normalizer: IngredientNormalizer = IngredientNormalizer()
    ) {
        self.ingredientStore = ingredientStore
        self.searchService = searchService ?? Self.resolveSearchService()
        self.planner = planner
        self.matcher = matcher
        self.normalizer = normalizer
        self.ingredientCount = ingredientStore.ingredients.count

        ingredientSink = ingredientStore.$ingredients.sink { [weak self] ingredients in
            self?.ingredientCount = ingredients.count
        }
    }

    public func refresh() async {
        let pantry = ingredientStore.ingredients
        guard !pantry.isEmpty else {
            readyMatches = []
            almostMatches = []
            isLoading = false
            errorMessage = nil
            return
        }

        let allIngredients = pantry + stapleIngredients()

        isLoading = true
        errorMessage = nil

        do {
            let plan = planner.makePlan(from: allIngredients)
            let candidates = try await searchService.search(query: plan.query)
            let results = matcher.match(
                ingredients: allIngredients,
                recipes: candidates,
                context: plan.matchingContext
            )
            readyMatches = results.ready
            almostMatches = Array(
                results.almost
                    .filter { $0.coverage >= Self.minCoverageToShow }
                    .prefix(Self.maxAlmostToShow)
            )
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Recipe search failed. Try again."
        }
    }

    public func toggleStaple(_ name: String) {
        if excludedStaples.contains(name) {
            excludedStaples.remove(name)
        } else {
            excludedStaples.insert(name)
        }
    }

    public func isStapleIncluded(_ name: String) -> Bool {
        !excludedStaples.contains(name)
    }

    private func stapleIngredients() -> [Ingredient] {
        let pantryCanonicals = Set(ingredientStore.ingredients.map(\.canonicalName))
        return activeStaples
            .map { Ingredient(name: $0, canonicalName: normalizer.canonicalize($0)) }
            // Skip staples already in pantry to avoid duplicate canonicals
            .filter { !pantryCanonicals.contains($0.canonicalName) }
    }

    private static func resolveSearchService() -> any RecipeSearchService {
        let live = LiveRecipeSearchServiceFactory.makeDefault()
        if live is MissingRecipeAPIConfigurationService {
            print("[Recommendations] Using LocalSeedRecipeSearchService (no Edamam credentials)")
            return LocalSeedRecipeSearchService()
        }
        print("[Recommendations] Using EdamamRecipeSearchService")
        return live
    }
}
