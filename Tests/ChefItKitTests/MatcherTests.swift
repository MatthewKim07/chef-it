import Testing
@testable import ChefItKit

@Suite("RecipeMatcher")
struct MatcherTests {
    let matcher = RecipeMatcher()
    let normalizer = IngredientNormalizer()

    private func ingredient(_ raw: String) -> Ingredient {
        Ingredient(name: raw, canonicalName: normalizer.canonicalize(raw))
    }

    @Test func readyWhenAllPresent() {
        let pantry = ["pasta", "garlic", "olive oil", "salt"].map(ingredient)
        let results = matcher.match(ingredients: pantry, recipes: SeedRecipes.all)
        #expect(results.ready.contains { $0.recipe.id == "garlic-oil-pasta" })
        let pasta = results.ready.first { $0.recipe.id == "garlic-oil-pasta" }
        #expect(pasta?.missingIngredients == [])
    }

    @Test func almostWhenOneMissing() {
        let pantry = ["egg", "tomato", "salt"].map(ingredient)
        let results = matcher.match(ingredients: pantry, recipes: SeedRecipes.all)
        let almost = results.almost.first { $0.recipe.id == "tomato-egg-stir" }
        #expect(almost != nil)
        #expect(almost?.missingIngredients == ["rice"])
    }

    @Test func excludedBeyondThreshold() {
        let pantry = ["egg"].map(ingredient)
        let results = matcher.match(ingredients: pantry, recipes: SeedRecipes.all)
        // tomato-egg-stir needs egg+tomato+salt+rice → 3 missing > default threshold 2
        #expect(!results.ready.contains { $0.recipe.id == "tomato-egg-stir" })
        #expect(!results.almost.contains { $0.recipe.id == "tomato-egg-stir" })
    }

    @Test func readySortedByCookingTime() {
        let pantry = ["pasta", "garlic", "olive oil", "salt", "egg", "tomato", "rice"].map(ingredient)
        let results = matcher.match(ingredients: pantry, recipes: SeedRecipes.all)
        let times = results.ready.map(\.recipe.cookingMinutes)
        #expect(times == times.sorted())
    }

    @Test func canonicalizationLetsRawFormsMatch() {
        let pantry = ["Cherry Tomatoes", "Eggs", "Kosher Salt", "white rice"].map(ingredient)
        let results = matcher.match(ingredients: pantry, recipes: SeedRecipes.all)
        #expect(results.ready.contains { $0.recipe.id == "tomato-egg-stir" })
    }

    @Test func emptyPantryProducesNoReady() {
        let results = matcher.match(ingredients: [], recipes: SeedRecipes.all)
        #expect(results.ready.isEmpty)
    }
}
