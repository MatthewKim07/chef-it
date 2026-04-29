import Testing
@testable import ChefItKit

@MainActor
@Suite("ChefItMilestoneOneViewModel")
struct MilestoneOneViewModelTests {
    private func makeModel() -> ChefItMilestoneOneViewModel {
        let store = IngredientStore(persister: InMemoryIngredientPersister())
        let favorites = FavoriteRecipeStore(persister: InMemoryFavoriteRecipePersister())
        return ChefItMilestoneOneViewModel(
            ingredientStore: store,
            favoriteRecipeStore: favorites
        )
    }

    @Test func addManualUpdatesFeedback() {
        let model = makeModel()
        model.manualEntry = "tomato, garlic"
        model.addManualIngredients()
        #expect(model.lastAddFeedback?.added == 2)
        #expect(model.lastAddFeedback?.duplicates == 0)
        #expect(model.manualEntry.isEmpty)
    }

    @Test func duplicateAddIsReportedNotDestructive() {
        let model = makeModel()
        model.manualEntry = "tomato"
        model.addManualIngredients()
        model.manualEntry = "Cherry Tomatoes"
        model.addManualIngredients()
        #expect(model.ingredients.count == 1)
        #expect(model.lastAddFeedback?.duplicates == 1)
    }

    @Test func suggestionsExcludeBoardItems() {
        let model = makeModel()
        model.manualEntry = "tom"
        // Should suggest tomato (not on board yet)
        #expect(model.suggestions.contains("tomato"))

        model.acceptSuggestion("tomato")
        // After acceptance, manualEntry cleared → no suggestions
        #expect(model.manualEntry.isEmpty)
        #expect(model.suggestions.isEmpty)

        // Re-querying excludes the just-added item
        model.manualEntry = "tom"
        #expect(!model.suggestions.contains("tomato"))
    }

    @Test func clearStoresUndoSnapshot() {
        let model = makeModel()
        model.manualEntry = "egg, tomato"
        model.addManualIngredients()
        #expect(model.ingredients.count == 2)

        model.clearBoard()
        #expect(model.ingredients.isEmpty)
        #expect(model.undoableClearSnapshot?.count == 2)

        model.undoClear()
        #expect(model.ingredients.count == 2)
        #expect(model.undoableClearSnapshot == nil)
    }

    @Test func renameFlowSurfacesDuplicateConflict() {
        let model = makeModel()
        model.manualEntry = "tomato, garlic"
        model.addManualIngredients()

        let garlicID = model.ingredients.first { $0.canonicalName == "garlic" }!.id
        model.beginEdit(garlicID)
        if case .editing = model.editState {} else { Issue.record("expected editing") }

        model.updateEditDraft("Cherry Tomatoes")
        model.commitEdit()
        if case .duplicateConflict = model.editState {} else { Issue.record("expected duplicateConflict") }
        // Board untouched
        #expect(model.ingredients.count == 2)

        model.cancelEdit()
        if case .idle = model.editState {} else { Issue.record("expected idle") }
    }

    @Test func togglingFavoriteRecipeUpdatesState() {
        let model = makeModel()
        let recipe = Recipe(
            id: "saved-recipe",
            title: "Skillet Pasta",
            blurb: "Quick pantry dinner.",
            cookingMinutes: 20,
            ingredients: ["pasta", "tomato", "garlic"]
        )

        #expect(!model.isFavorite(recipe))
        model.toggleFavorite(recipe)
        #expect(model.isFavorite(recipe))
        #expect(model.favoriteRecipeIDs.contains(recipe.id))

        model.toggleFavorite(recipe)
        #expect(!model.isFavorite(recipe))
        #expect(!model.favoriteRecipeIDs.contains(recipe.id))
    }
}
