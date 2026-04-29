import Testing
@testable import ChefItKit

/// End-to-end matching scenarios from MILESTONES.md M3.
/// Each scenario seeds a pantry, runs the planner + matcher pipeline, and
/// asserts the expected ready/almost grouping on the seed corpus.
@Suite("Matching scenarios")
struct MatchingScenariosTests {
    let normalizer = IngredientNormalizer()
    let planner = RecipeDiscoveryPlanner()
    let matcher = RecipeMatcher()

    private func ingredient(_ raw: String) -> Ingredient {
        Ingredient(name: raw, canonicalName: normalizer.canonicalize(raw))
    }

    private func run(_ raw: [String]) -> MatchResults {
        let ingredients = raw.map(ingredient)
        let plan = planner.makePlan(from: ingredients)
        return matcher.match(
            ingredients: ingredients,
            recipes: SeedRecipes.all,
            context: plan.matchingContext
        )
    }

    @Test func eggsTomatoesRiceSalt_putsTomatoEggReady() {
        let r = run(["eggs", "cherry tomatoes", "white rice", "kosher salt"])
        let readyIDs = r.ready.map(\.recipe.id)
        #expect(readyIDs.contains("tomato-egg-stir"))
    }

    @Test func chickenLemonGarlic_putsLemonChickenAlmost() {
        let r = run(["chicken", "lemon", "garlic"])
        let almostIDs = r.almost.map(\.recipe.id)
        #expect(almostIDs.contains("lemon-chicken"))
        let lemonChicken = r.almost.first { $0.recipe.id == "lemon-chicken" }!
        #expect(lemonChicken.missingIngredients.count == 2)
    }

    @Test func shrimpGarlicButterLemonPasta_putsScampiAlmost() {
        let r = run(["shrimp", "garlic", "butter", "lemon", "pasta"])
        let almostIDs = r.almost.map(\.recipe.id)
        #expect(almostIDs.contains("shrimp-scampi"))
        let scampi = r.almost.first { $0.recipe.id == "shrimp-scampi" }!
        #expect(scampi.missingIngredients == ["parsley"])
    }

    @Test func tofuScallionMiso_putsMisoSoupReady() {
        let r = run(["tofu", "scallion", "miso"])
        #expect(r.ready.contains { $0.recipe.id == "miso-soup" })
    }

    @Test func tomatoGarlic_yieldsAlmostThereCandidates() {
        let r = run(["tomato", "garlic"])
        // Marinara needs only 2 more (olive oil, salt) → within threshold
        let ids = r.almost.map(\.recipe.id)
        #expect(ids.contains("marinara-base"))
    }

    @Test func emptyPantry_isFullyEmpty() {
        let r = run([])
        #expect(r.ready.isEmpty)
        #expect(r.almost.isEmpty)
    }

    @Test func proteinHitOutranksNonProtein() {
        // Pantry has chicken + several pasta-friendly staples. The planner
        // marks `chicken` as a protein. A chicken-built recipe should outrank
        // a non-protein pasta recipe with similar coverage.
        let r = run(["chicken", "garlic", "rice", "olive oil", "salt"])
        guard let first = r.ready.first else {
            Issue.record("expected at least one ready recipe")
            return
        }
        // garlic-chicken-rice has 0 missing and contains the planner protein.
        #expect(first.recipe.id == "garlic-chicken-rice")
    }

    @Test func readyOrderingIsDeterministic() {
        // Run twice; expect identical ordering.
        let a = run(["egg", "tomato", "salt", "rice", "scallion", "soy sauce", "garlic"])
        let b = run(["egg", "tomato", "salt", "rice", "scallion", "soy sauce", "garlic"])
        #expect(a.ready.map(\.recipe.id) == b.ready.map(\.recipe.id))
    }
}
