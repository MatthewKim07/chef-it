import XCTest
@testable import ChefItKit

final class RecipeDiscoveryPlannerTests: XCTestCase {
    private let normalizer = IngredientNormalizer()
    private let planner = RecipeDiscoveryPlanner()

    private func ingredient(_ raw: String) -> Ingredient {
        Ingredient(name: raw, canonicalName: normalizer.canonicalize(raw))
    }

    func testPlannerSeparatesProteinsFromSupportingIngredients() {
        let ingredients = [
            ingredient("Chicken Breast"),
            ingredient("Cherry Tomatoes"),
            ingredient("Garlic"),
            ingredient("White Rice")
        ]

        let plan = planner.makePlan(from: ingredients)

        XCTAssertEqual(plan.proteins, ["chicken"])
        XCTAssertEqual(plan.supportingIngredients, ["tomato", "garlic", "rice"])
        XCTAssertEqual(plan.query.proteins, ["chicken"])
    }

    func testLocalSeedSearchPrioritizesProteinMatches() async throws {
        let service = LocalSeedRecipeSearchService()
        let query = RecipeQuery(canonicalIngredients: ["chicken", "garlic"], proteins: ["chicken"])

        let recipes = try await service.search(query: query)

        XCTAssertEqual(recipes.first?.id, "lemon-chicken")
    }
}
