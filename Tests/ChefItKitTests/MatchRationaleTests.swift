import Testing
@testable import ChefItKit

@Suite("Match rationale")
struct MatchRationaleTests {
    let matcher = RecipeMatcher()
    let normalizer = IngredientNormalizer()

    private func ingredient(_ raw: String) -> Ingredient {
        Ingredient(name: raw, canonicalName: normalizer.canonicalize(raw))
    }

    @Test func readyRationaleStatesFullCoverage() {
        let pantry = ["miso", "tofu", "scallion"].map(ingredient)
        let context = RecipeMatchingContext(plannerProteins: ["tofu"])
        let results = matcher.match(
            ingredients: pantry,
            recipes: SeedRecipes.all,
            context: context
        )
        let miso = results.ready.first { $0.recipe.id == "miso-soup" }
        #expect(miso != nil)
        let r = miso!.rationale
        #expect(r.contains { $0.contains("All 3 ingredients on board") })
        #expect(r.contains { $0.contains("Built around your tofu") })
        #expect(r.contains { $0.contains("Quick — 10 min") })
    }

    @Test func almostRationalePluralizesAndPreviewsMissing() {
        let pantry = ["chicken", "lemon", "garlic"].map(ingredient)
        let context = RecipeMatchingContext(plannerProteins: ["chicken"])
        let results = matcher.match(
            ingredients: pantry,
            recipes: SeedRecipes.all,
            context: context
        )
        let lemonChicken = results.almost.first { $0.recipe.id == "lemon-chicken" }!
        let r = lemonChicken.rationale
        #expect(r.contains { $0.starts(with: "Need 2 more") })
        #expect(r.contains { $0.contains("Built around your chicken") })
    }

    @Test func almostRationaleSingularWhenOneMissing() {
        let pantry = ["shrimp", "garlic", "butter", "lemon", "pasta"].map(ingredient)
        let context = RecipeMatchingContext(plannerProteins: ["shrimp"])
        let results = matcher.match(
            ingredients: pantry,
            recipes: SeedRecipes.all,
            context: context
        )
        let scampi = results.almost.first { $0.recipe.id == "shrimp-scampi" }!
        #expect(scampi.rationale.contains { $0 == "Need 1 more: parsley." })
    }

    @Test func coveragePercentDerivedFromMatched() {
        let pantry = ["chicken", "lemon", "garlic"].map(ingredient)
        let results = matcher.match(ingredients: pantry, recipes: SeedRecipes.all)
        let lemonChicken = results.almost.first { $0.recipe.id == "lemon-chicken" }!
        // lemon-chicken has 5 ingredients, matched 3 → 60%
        #expect(lemonChicken.coveragePercent == 60)
    }
}
