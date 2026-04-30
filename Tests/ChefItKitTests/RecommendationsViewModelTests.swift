import Testing
@testable import ChefItKit

@MainActor
@Suite("RecommendationsViewModel")
struct RecommendationsViewModelTests {

    private func makeVM(ingredients: [String] = []) -> RecommendationsViewModel {
        let store = IngredientStore(persister: InMemoryIngredientPersister())
        if !ingredients.isEmpty {
            store.parseAndAdd(ingredients.joined(separator: ", "))
        }
        return RecommendationsViewModel(ingredientStore: store)
    }

    @Test("Empty pantry: refresh skips search, no results, no error")
    func emptyPantryProducesNoResults() async {
        let vm = makeVM()
        await vm.refresh()
        #expect(!vm.isLoading)
        #expect(vm.readyMatches.isEmpty)
        #expect(vm.almostMatches.isEmpty)
        #expect(vm.errorMessage == nil)
    }

    @Test("Missing Edamam credentials fall back to local seed — no error thrown")
    func missingCredentialsFallsBackToLocalSeed() async {
        // RecipeAPIConfiguration.fromEnvironment returns nil in test environment
        // so resolveSearchService() picks LocalSeedRecipeSearchService.
        let vm = makeVM(ingredients: ["pasta", "garlic", "olive oil", "salt"])
        await vm.refresh()
        #expect(vm.errorMessage == nil)
        // garlic-oil-pasta seed recipe should be ready
        let hasReady = vm.readyMatches.contains { $0.recipe.id == "garlic-oil-pasta" }
        #expect(hasReady)
    }

    @Test("Ready vs almost grouping is mutually exclusive and correct")
    func groupingIsCorrect() async {
        let vm = makeVM(ingredients: ["pasta", "garlic", "olive oil", "salt"])
        await vm.refresh()
        #expect(vm.readyMatches.allSatisfy { $0.status == .ready })
        #expect(vm.almostMatches.allSatisfy { $0.status == .almost })
        // No overlap
        let readyIDs = Set(vm.readyMatches.map(\.id))
        let almostIDs = Set(vm.almostMatches.map(\.id))
        #expect(readyIDs.isDisjoint(with: almostIDs))
    }

    @Test("Ranking is deterministic across repeated refresh calls")
    func rankingIsDeterministic() async {
        let vm = makeVM(ingredients: ["pasta", "garlic", "olive oil", "salt", "egg", "tomato", "rice"])
        await vm.refresh()
        let firstReady = vm.readyMatches.map(\.id)
        let firstAlmost = vm.almostMatches.map(\.id)
        await vm.refresh()
        #expect(vm.readyMatches.map(\.id) == firstReady)
        #expect(vm.almostMatches.map(\.id) == firstAlmost)
    }

    @Test("ingredientCount tracks store mutations")
    func ingredientCountTracksStore() async {
        let store = IngredientStore(persister: InMemoryIngredientPersister())
        let vm = RecommendationsViewModel(ingredientStore: store)
        #expect(vm.ingredientCount == 0)
        store.parseAndAdd("tomato, garlic")
        await Task.yield()
        #expect(vm.ingredientCount == 2)
        store.parseAndAdd("egg")
        await Task.yield()
        #expect(vm.ingredientCount == 3)
    }

    @Test("Ready recipes have zero missing ingredients")
    func readyRecipesHaveNoMissing() async {
        let vm = makeVM(ingredients: ["pasta", "garlic", "olive oil", "salt"])
        await vm.refresh()
        #expect(vm.readyMatches.allSatisfy { $0.missingIngredients.isEmpty })
    }

    @Test("Almost recipes have at least one missing ingredient")
    func almostRecipesHaveMissing() async {
        let vm = makeVM(ingredients: ["egg", "tomato", "salt"])
        await vm.refresh()
        #expect(vm.almostMatches.allSatisfy { !$0.missingIngredients.isEmpty })
    }

    @Test("coveragePercent is in 0–100 range for all results")
    func coveragePercentInBounds() async {
        let vm = makeVM(ingredients: ["pasta", "garlic", "olive oil", "salt", "egg", "tomato", "rice"])
        await vm.refresh()
        let all = vm.readyMatches + vm.almostMatches
        #expect(all.allSatisfy { $0.coveragePercent >= 0 && $0.coveragePercent <= 100 })
    }

    @Test("Default staples are all included by default")
    func defaultStaplesAllIncluded() {
        let vm = makeVM()
        for staple in RecommendationsViewModel.defaultStaples {
            #expect(vm.isStapleIncluded(staple))
        }
        #expect(vm.activeStaples.count == RecommendationsViewModel.defaultStaples.count)
    }

    @Test("toggleStaple removes and re-adds staple")
    func toggleStapleFlipsInclusion() {
        let vm = makeVM()
        vm.toggleStaple("salt")
        #expect(!vm.isStapleIncluded("salt"))
        #expect(!vm.activeStaples.contains("salt"))
        vm.toggleStaple("salt")
        #expect(vm.isStapleIncluded("salt"))
        #expect(vm.activeStaples.contains("salt"))
    }

    @Test("Staples enable Ready status for recipes that only need pantry + staples")
    func staplesEnableReadyStatus() async {
        // garlic-oil-pasta needs: pasta, garlic, olive oil, salt
        // Without staples (only pasta+garlic in pantry) → almost (missing oil+salt)
        // With default staples → ready (oil+salt auto-included)
        let vm = makeVM(ingredients: ["pasta", "garlic"])
        await vm.refresh()
        let isReady = vm.readyMatches.contains { $0.recipe.id == "garlic-oil-pasta" }
        #expect(isReady)
    }

    @Test("Excluded staples don't count toward coverage")
    func excludedStapleNotInjected() async {
        // Same setup as above, but exclude salt → garlic-oil-pasta should NOT be ready
        let vm = makeVM(ingredients: ["pasta", "garlic"])
        vm.toggleStaple("salt")
        await vm.refresh()
        let isReady = vm.readyMatches.contains { $0.recipe.id == "garlic-oil-pasta" }
        #expect(!isReady)
    }
}
