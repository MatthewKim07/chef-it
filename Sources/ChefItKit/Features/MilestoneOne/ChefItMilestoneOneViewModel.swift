import Combine
import Foundation

public enum DiscoveryWorkspacePhase {
    case needsIngredients
    case staged
    case loading
    case loaded(DiscoveryWorkspaceSnapshot)
    case failed(String)
}

public struct DiscoveryWorkspaceSnapshot: Sendable {
    public let plan: RecipeDiscoveryPlan
    public let candidateCount: Int
    public let results: MatchResults

    public init(
        plan: RecipeDiscoveryPlan,
        candidateCount: Int,
        results: MatchResults
    ) {
        self.plan = plan
        self.candidateCount = candidateCount
        self.results = results
    }
}

/// Milestone 1 coordinator:
/// - manual ingredient intake is live
/// - scan entry is represented but not executed yet
/// - recipe discovery uses local seed data behind the same boundaries a real
///   API-backed implementation will use in later milestones
@MainActor
public final class ChefItMilestoneOneViewModel: ObservableObject {
    @Published public var manualEntry: String = ""
    @Published public private(set) var phase: DiscoveryWorkspacePhase = .needsIngredients

    public let ingredientStore: IngredientStore

    private let planner: RecipeDiscoveryPlanner
    private let matcher: RecipeMatcher
    private let recipeSearchService: any RecipeSearchService
    private var ingredientsObservation: AnyCancellable?

    public init(
        ingredientStore: IngredientStore? = nil,
        planner: RecipeDiscoveryPlanner = RecipeDiscoveryPlanner(),
        matcher: RecipeMatcher = RecipeMatcher(),
        recipeSearchService: any RecipeSearchService = LocalSeedRecipeSearchService()
    ) {
        self.ingredientStore = ingredientStore ?? IngredientStore()
        self.planner = planner
        self.matcher = matcher
        self.recipeSearchService = recipeSearchService

        ingredientsObservation = self.ingredientStore.$ingredients.sink { [weak self] ingredients in
            guard let self else { return }
            if ingredients.isEmpty {
                self.phase = .needsIngredients
                return
            }

            switch self.phase {
            case .loading:
                break
            default:
                self.phase = .staged
            }
        }
    }

    public var ingredients: [Ingredient] {
        ingredientStore.ingredients
    }

    public func addManualIngredients() {
        guard !manualEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        ingredientStore.parseAndAdd(manualEntry)
        manualEntry = ""
    }

    public func removeIngredient(_ id: Ingredient.ID) {
        ingredientStore.remove(id)
    }

    public func clearBoard() {
        ingredientStore.clear()
    }

    public func refreshWorkspace(
        dietaryTags: [String] = [],
        maxCookingMinutes: Int? = nil
    ) async {
        guard !ingredients.isEmpty else {
            phase = .needsIngredients
            return
        }

        phase = .loading

        do {
            let plan = planner.makePlan(
                from: ingredients,
                dietaryTags: dietaryTags,
                maxCookingMinutes: maxCookingMinutes
            )
            let candidates = try await recipeSearchService.search(query: plan.query)
            let results = matcher.match(ingredients: ingredients, recipes: candidates)

            phase = .loaded(
                DiscoveryWorkspaceSnapshot(
                    plan: plan,
                    candidateCount: candidates.count,
                    results: results
                )
            )
        } catch {
            phase = .failed(
                "Milestone 1 keeps recipe search local. The live API connector is deferred, but this shell is ready for it."
            )
        }
    }
}
