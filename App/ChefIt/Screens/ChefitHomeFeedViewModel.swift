import ChefItKit
import Foundation

enum MealContext: Hashable {
    case breakfast
    case lunch
    case dinner
    case lateNight

    init(hour: Int) {
        switch hour {
        case 5..<11: self = .breakfast
        case 11..<16: self = .lunch
        case 16..<22: self = .dinner
        default: self = .lateNight
        }
    }

    var maxTime: Int {
        switch self {
        case .breakfast: return 15
        case .lunch: return 25
        case .dinner: return 45
        case .lateNight: return 10
        }
    }

    var subtitle: String {
        switch self {
        case .breakfast: return "Quick breakfast ideas from your pantry"
        case .lunch: return "Fast lunch ideas based on what you have"
        case .dinner: return "Quick dinner ideas based on your pantry"
        case .lateNight: return "Late-night bites with what is left"
        }
    }

    var contextBadge: String {
        switch self {
        case .breakfast: return "🍳 Easy"
        case .lunch: return "⚡ Quick"
        case .dinner: return "🍽 Tonight"
        case .lateNight: return "🌙 Late Night"
        }
    }
}

enum RecipeBadge: Hashable {
    case quick
    case easy
    case onePan
    case healthy
    case highProtein

    var title: String {
        switch self {
        case .quick: return "⚡ Quick"
        case .easy: return "🍳 Easy"
        case .onePan: return "🍽 1 pan"
        case .healthy: return "🥗 Healthy"
        case .highProtein: return "💪 Protein"
        }
    }
}

struct RecipeUIModel: Identifiable, Hashable {
    let recipe: Recipe
    let matchScore: Double
    let badges: [RecipeBadge]
    let previewIngredients: [String]
    let expiringIngredient: String?
    let contextBadge: String

    var id: String { recipe.id }

    var matchPercentText: String {
        "\(Int((matchScore * 100).rounded()))% match"
    }
}

@MainActor
final class HomeFeedViewModel: ObservableObject {
    @Published private(set) var forYouRecipes: [RecipeUIModel] = []
    @Published private(set) var expiringRecipes: [RecipeUIModel] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var forYouSubtitle: String = MealContext(hour: 18).subtitle

    @Published private(set) var recipeByID: [String: ChefitRecipeItem] = [:]

    private let recipeSearchService: any RecipeSearchService
    private let fallbackSearchService: any RecipeSearchService
    private let planner: RecipeDiscoveryPlanner
    private let normalizer: IngredientNormalizer

    private var loadTask: Task<Void, Never>?
    private var cache: [FeedCacheKey: FeedCacheValue] = [:]

    init(
        recipeSearchService: any RecipeSearchService = LiveRecipeSearchServiceFactory.makeDefault(),
        fallbackSearchService: any RecipeSearchService = LocalSeedRecipeSearchService(),
        planner: RecipeDiscoveryPlanner = RecipeDiscoveryPlanner(),
        normalizer: IngredientNormalizer = IngredientNormalizer()
    ) {
        self.recipeSearchService = recipeSearchService
        self.fallbackSearchService = fallbackSearchService
        self.planner = planner
        self.normalizer = normalizer
    }

    func scheduleLoad(pantryItems: [Ingredient]) {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard let self else { return }
            await self.loadFeed(pantryItems: pantryItems)
        }
    }

    func loadFeed(pantryItems: [Ingredient]) async {
        let hour = Calendar.current.component(.hour, from: Date())
        let context = MealContext(hour: hour)
        forYouSubtitle = context.subtitle

        let pantryCanonical = pantryItems.map(\.canonicalName)
        let expiring = pantryItems.filter {
            guard let freshness = $0.freshness() else { return false }
            return freshness < 0.4
        }

        let key = FeedCacheKey(
            context: context,
            pantryDigest: pantryCanonical.sorted().joined(separator: "|"),
            expiringDigest: expiring.map(\.canonicalName).sorted().joined(separator: "|")
        )
        if let cached = cache[key] {
            forYouRecipes = cached.forYou
            expiringRecipes = cached.expiring
            recipeByID = cached.recipeByID
            return
        }

        isLoading = true
        defer { isLoading = false }

        let plan = planner.makePlan(
            from: pantryItems,
            maxCookingMinutes: context.maxTime
        )
        let fetched = await fetchRecipes(query: plan.query)
        let recipes = fetched.isEmpty ? SeedRecipes.all : fetched

        let forYou = rankForYou(
            recipes: recipes,
            pantryCanonical: Set(pantryCanonical),
            context: context
        )
        let useSoon = rankUseSoon(
            recipes: recipes,
            expiring: expiring,
            pantryCanonical: Set(pantryCanonical),
            context: context
        )

        forYouRecipes = Array(forYou.prefix(8))
        expiringRecipes = Array(useSoon.prefix(8))
        recipeByID = Dictionary(
            uniqueKeysWithValues: (forYouRecipes + expiringRecipes).map { ui in
                (ui.id, chefitItem(from: ui.recipe))
            }
        )

        cache[key] = FeedCacheValue(
            forYou: forYouRecipes,
            expiring: expiringRecipes,
            recipeByID: recipeByID
        )
    }

    private func fetchRecipes(query: RecipeQuery) async -> [Recipe] {
        do {
            return try await recipeSearchService.search(query: query)
        } catch {
            do {
                return try await fallbackSearchService.search(query: query)
            } catch {
                return []
            }
        }
    }

    private func rankForYou(
        recipes: [Recipe],
        pantryCanonical: Set<String>,
        context: MealContext
    ) -> [RecipeUIModel] {
        recipes
            .map { recipe in
                let ingredientMatch = ingredientCoverage(recipe: recipe, pantryCanonical: pantryCanonical)
                let timeFit = timeFit(recipe: recipe, context: context)
                let userPreference = preferenceScore(recipe: recipe)
                let score = (ingredientMatch * 0.5) + (timeFit * 0.3) + (userPreference * 0.2)
                return RecipeUIModel(
                    recipe: recipe,
                    matchScore: score,
                    badges: buildBadges(recipe: recipe),
                    previewIngredients: recipe.ingredients.prefix(3).map { normalizer.canonicalize($0) },
                    expiringIngredient: nil,
                    contextBadge: context.contextBadge
                )
            }
            .sorted {
                if $0.matchScore != $1.matchScore {
                    return $0.matchScore > $1.matchScore
                }
                return $0.recipe.cookingMinutes < $1.recipe.cookingMinutes
            }
    }

    private func rankUseSoon(
        recipes: [Recipe],
        expiring: [Ingredient],
        pantryCanonical: Set<String>,
        context: MealContext
    ) -> [RecipeUIModel] {
        let expiringCanonicals = Set(expiring.map(\.canonicalName))
        guard !expiringCanonicals.isEmpty else { return [] }

        return recipes.compactMap { recipe in
            let recipeCanonicals = Set(recipe.ingredients.map(normalizer.canonicalize))
            let hits = recipeCanonicals.intersection(expiringCanonicals)
            guard !hits.isEmpty else { return nil }

            let ingredientMatch = ingredientCoverage(recipe: recipe, pantryCanonical: pantryCanonical)
            let timeFit = timeFit(recipe: recipe, context: context)
            let useSoonBoost = Double(hits.count) / Double(max(1, recipeCanonicals.count))
            let score = (ingredientMatch * 0.45) + (timeFit * 0.25) + (useSoonBoost * 0.30)
            let firstExpiring = expiring.first(where: { hits.contains($0.canonicalName) })
            return RecipeUIModel(
                recipe: recipe,
                matchScore: score,
                badges: buildBadges(recipe: recipe),
                previewIngredients: recipe.ingredients.prefix(3).map { normalizer.canonicalize($0) },
                expiringIngredient: firstExpiring?.name,
                contextBadge: context.contextBadge
            )
        }
        .sorted {
            if $0.matchScore != $1.matchScore {
                return $0.matchScore > $1.matchScore
            }
            return $0.recipe.cookingMinutes < $1.recipe.cookingMinutes
        }
    }

    private func ingredientCoverage(recipe: Recipe, pantryCanonical: Set<String>) -> Double {
        let recipeCanonicals = Set(recipe.ingredients.map(normalizer.canonicalize))
        guard !recipeCanonicals.isEmpty else { return 0 }
        let hits = recipeCanonicals.intersection(pantryCanonical)
        return Double(hits.count) / Double(recipeCanonicals.count)
    }

    private func timeFit(recipe: Recipe, context: MealContext) -> Double {
        if recipe.cookingMinutes <= context.maxTime {
            return 1
        }
        let over = recipe.cookingMinutes - context.maxTime
        return max(0.1, 1 - (Double(over) / Double(context.maxTime)))
    }

    private func preferenceScore(recipe: Recipe) -> Double {
        var score = 0.45
        if recipe.difficulty == .easy { score += 0.25 }
        if recipe.dietaryTags.contains(where: { $0.lowercased().contains("healthy") }) { score += 0.15 }
        if recipe.ingredients.contains(where: { ingredient in
            let canonical = normalizer.canonicalize(ingredient)
            return ["chicken", "beef", "salmon", "egg", "shrimp", "tuna"].contains(canonical)
        }) {
            score += 0.15
        }
        return min(score, 1)
    }

    private func buildBadges(recipe: Recipe) -> [RecipeBadge] {
        var badges: [RecipeBadge] = []
        if recipe.cookingMinutes <= 20 { badges.append(.quick) }
        if recipe.difficulty == .easy { badges.append(.easy) }
        if recipe.ingredients.count <= 6 { badges.append(.onePan) }
        if recipe.dietaryTags.contains(where: { $0.lowercased().contains("healthy") }) {
            badges.append(.healthy)
        }
        if recipe.ingredients.contains(where: { ingredient in
            let canonical = normalizer.canonicalize(ingredient)
            return ["chicken", "beef", "salmon", "egg", "shrimp", "tuna"].contains(canonical)
        }) {
            badges.append(.highProtein)
        }
        return badges
    }

    private func chefitItem(from recipe: Recipe) -> ChefitRecipeItem {
        ChefitRecipeItem(
            id: recipe.id,
            title: recipe.title,
            imageURL: recipe.imageURL,
            minutes: recipe.cookingMinutes,
            difficulty: recipe.difficulty.rawValue.capitalized
        )
    }
}

private struct FeedCacheKey: Hashable {
    let context: MealContext
    let pantryDigest: String
    let expiringDigest: String
}

private struct FeedCacheValue {
    let forYou: [RecipeUIModel]
    let expiring: [RecipeUIModel]
    let recipeByID: [String: ChefitRecipeItem]
}
