import Testing
@testable import ChefItKit

@Suite("Match ranking stability")
struct MatchRankingStabilityTests {
    let matcher = RecipeMatcher()

    private func recipe(id: String, minutes: Int, ingredients: [String]) -> Recipe {
        Recipe(
            id: id,
            title: id,
            blurb: "",
            cookingMinutes: minutes,
            servings: 2,
            ingredients: ingredients
        )
    }

    @Test func tiebreakerByCookingTimeThenID() {
        // Three recipes with identical coverage → tiebreaker = time, then id.
        let recipes = [
            recipe(id: "z", minutes: 20, ingredients: ["a", "b"]),
            recipe(id: "a", minutes: 20, ingredients: ["a", "b"]),
            recipe(id: "m", minutes: 10, ingredients: ["a", "b"])
        ]
        let pantry = [
            Ingredient(name: "a", canonicalName: "a"),
            Ingredient(name: "b", canonicalName: "b")
        ]
        let r = matcher.match(ingredients: pantry, recipes: recipes)
        #expect(r.ready.map(\.recipe.id) == ["m", "a", "z"])
    }

    @Test func proteinHitBoostsAcrossEqualCoverage() {
        // Two ready recipes, both 100% covered, both 20 min.
        // One contains the planner protein, the other does not.
        let plain = recipe(id: "plain-pasta", minutes: 20, ingredients: ["pasta", "salt"])
        let chickenRecipe = recipe(id: "chicken-bowl", minutes: 20, ingredients: ["chicken", "rice"])
        let pantry = [
            Ingredient(name: "pasta", canonicalName: "pasta"),
            Ingredient(name: "salt", canonicalName: "salt"),
            Ingredient(name: "chicken", canonicalName: "chicken"),
            Ingredient(name: "rice", canonicalName: "rice")
        ]
        let context = RecipeMatchingContext(plannerProteins: ["chicken"])
        let r = matcher.match(
            ingredients: pantry,
            recipes: [plain, chickenRecipe],
            context: context
        )
        #expect(r.ready.first?.recipe.id == "chicken-bowl")
    }

    @Test func almostThresholdControlsExclusion() {
        let lax = RecipeMatcher(almostThreshold: 5)
        let tight = RecipeMatcher(almostThreshold: 1)
        let pantry = [Ingredient(name: "egg", canonicalName: "egg")]
        // Tomato-egg-stir needs 4 ingredients → 3 missing.
        let laxResults = lax.match(ingredients: pantry, recipes: SeedRecipes.all)
        let tightResults = tight.match(ingredients: pantry, recipes: SeedRecipes.all)
        #expect(laxResults.almost.contains { $0.recipe.id == "tomato-egg-stir" })
        #expect(!tightResults.almost.contains { $0.recipe.id == "tomato-egg-stir" })
    }

    @Test func scoreOrderingIsMonotonicWithinGroup() {
        let pantry = [
            Ingredient(name: "egg", canonicalName: "egg"),
            Ingredient(name: "tomato", canonicalName: "tomato"),
            Ingredient(name: "salt", canonicalName: "salt"),
            Ingredient(name: "rice", canonicalName: "rice"),
            Ingredient(name: "scallion", canonicalName: "scallion"),
            Ingredient(name: "garlic", canonicalName: "garlic"),
            Ingredient(name: "soy sauce", canonicalName: "soy sauce")
        ]
        let r = matcher.match(ingredients: pantry, recipes: SeedRecipes.all)
        let scores = r.ready.map(\.score)
        #expect(scores == scores.sorted(by: >))
    }
}
