import Foundation
import Testing
@testable import ChefItKit

@Suite("IngredientPersisting")
struct IngredientPersistingTests {
    @Test func userDefaultsRoundTrip() throws {
        let suiteName = "ChefItTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let persister = UserDefaultsIngredientPersister(defaults: defaults, key: "board")

        let original = [
            Ingredient(name: "Cherry Tomatoes", canonicalName: "tomato", category: .produce, source: .manual),
            Ingredient(name: "Garlic", canonicalName: "garlic", category: .produce, source: .scan)
        ]
        try persister.save(original)
        let loaded = try persister.load()

        #expect(loaded.count == 2)
        #expect(loaded.map(\.canonicalName) == ["tomato", "garlic"])
        #expect(loaded.map(\.source) == [.manual, .scan])
    }

    @Test func userDefaultsLoadsEmptyWhenAbsent() throws {
        let suiteName = "ChefItTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let persister = UserDefaultsIngredientPersister(defaults: defaults, key: "missing")
        let loaded = try persister.load()
        #expect(loaded.isEmpty)
    }

    @Test func userDefaultsCorruptedDataThrowsDecodingError() throws {
        let suiteName = "ChefItTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(Data([0xff, 0xfe, 0xfd]), forKey: "corrupt")
        let persister = UserDefaultsIngredientPersister(defaults: defaults, key: "corrupt")
        do {
            _ = try persister.load()
            Issue.record("expected throw")
        } catch IngredientPersistenceError.decodingFailed {
            // expected
        }
    }
}
