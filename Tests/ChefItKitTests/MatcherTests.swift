import XCTest
@testable import ChefItKit

final class MatcherTests: XCTestCase {
    let matcher = RecipeMatcher()
    let normalizer = IngredientNormalizer()

    private func ingredient(_ raw: String) -> Ingredient {
        let canonical = normalizer.canonicalize(raw)
        return Ingredient(name: raw, canonicalName: canonical)
    }

    func testReadyWhenAllPresent() {
        let pantry = ["pasta", "garlic", "olive oil", "salt"].map(ingredient)
        let results = matcher.match(ingredients: pantry, recipes: SeedRecipes.all)
        XCTAssertTrue(results.ready.contains { $0.recipe.id == "garlic-oil-pasta" })
        XCTAssertEqual(results.ready.first { $0.recipe.id == "garlic-oil-pasta" }?.missingIngredients, [])
    }

    func testAlmostWhenOneMissing() {
        let pantry = ["egg", "tomato", "salt"].map(ingredient)
        let results = matcher.match(ingredients: pantry, recipes: SeedRecipes.all)
        let almost = results.almost.first { $0.recipe.id == "tomato-egg-stir" }
        XCTAssertNotNil(almost)
        XCTAssertEqual(almost?.missingIngredients, ["rice"])
    }

    func testExcludedBeyondThreshold() {
        let pantry = ["egg"].map(ingredient)
        let results = matcher.match(ingredients: pantry, recipes: SeedRecipes.all)
        // tomato-egg-stir needs egg+tomato+salt+rice → 3 missing, beyond default threshold of 2
        XCTAssertNil(results.ready.first { $0.recipe.id == "tomato-egg-stir" })
        XCTAssertNil(results.almost.first { $0.recipe.id == "tomato-egg-stir" })
    }

    func testReadySortedByCookingTime() {
        let pantry = ["pasta", "garlic", "olive oil", "salt", "egg", "tomato", "rice"].map(ingredient)
        let results = matcher.match(ingredients: pantry, recipes: SeedRecipes.all)
        let times = results.ready.map(\.recipe.cookingMinutes)
        XCTAssertEqual(times, times.sorted())
    }

    func testCanonicalizationLetsRawFormsMatch() {
        let pantry = ["Cherry Tomatoes", "Eggs", "Kosher Salt", "white rice"].map(ingredient)
        let results = matcher.match(ingredients: pantry, recipes: SeedRecipes.all)
        XCTAssertTrue(results.ready.contains { $0.recipe.id == "tomato-egg-stir" })
    }

    func testEmptyPantryProducesNoReady() {
        let results = matcher.match(ingredients: [], recipes: SeedRecipes.all)
        XCTAssertTrue(results.ready.isEmpty)
    }
}
