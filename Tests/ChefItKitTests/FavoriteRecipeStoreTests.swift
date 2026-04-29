import Foundation
import Testing
@testable import ChefItKit

@Suite("FavoriteRecipeStore")
struct FavoriteRecipeStoreTests {
    @Test func inMemoryToggleRoundTrip() {
        let store = FavoriteRecipeStore(
            persister: InMemoryFavoriteRecipePersister(["recipe-1"])
        )

        #expect(store.isFavorite("recipe-1"))
        #expect(!store.isFavorite("recipe-2"))

        let recipe2State = store.toggle("recipe-2")
        #expect(recipe2State)
        #expect(store.isFavorite("recipe-2"))

        let recipe1State = store.toggle("recipe-1")
        #expect(!recipe1State)
        #expect(!store.isFavorite("recipe-1"))
    }

    @Test func userDefaultsPersisterRoundTrip() throws {
        let suiteName = "ChefItTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let persister = UserDefaultsFavoriteRecipePersister(defaults: defaults, key: "favorites")
        try persister.save(["recipe-a", "recipe-b"])
        let loaded = try persister.load()

        #expect(loaded.count == 2)
        #expect(loaded.contains("recipe-a"))
        #expect(loaded.contains("recipe-b"))
    }
}
