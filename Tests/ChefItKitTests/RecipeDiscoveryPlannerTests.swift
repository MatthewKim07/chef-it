import Testing
@testable import ChefItKit

@Suite("RecipeDiscoveryPlanner")
struct RecipeDiscoveryPlannerTests {
    let normalizer = IngredientNormalizer()
    let planner = RecipeDiscoveryPlanner()

    private func ingredient(_ raw: String) -> Ingredient {
        Ingredient(name: raw, canonicalName: normalizer.canonicalize(raw))
    }

    @Test func plannerSeparatesProteinsFromSupportingIngredients() {
        let ingredients = [
            ingredient("Chicken Breast"),
            ingredient("Cherry Tomatoes"),
            ingredient("Garlic"),
            ingredient("White Rice")
        ]

        let plan = planner.makePlan(from: ingredients)

        #expect(plan.proteins == ["chicken"])
        #expect(plan.supportingIngredients == ["tomato", "garlic", "rice"])
        #expect(plan.query.proteins == ["chicken"])
    }

    @Test func localSeedSearchPrioritizesProteinMatches() async throws {
        let service = LocalSeedRecipeSearchService()
        let query = RecipeQuery(canonicalIngredients: ["chicken", "garlic"], proteins: ["chicken"])

        let recipes = try await service.search(query: query)

        #expect(recipes.first?.id == "lemon-chicken")
    }
}
