import Foundation
import Testing
@testable import ChefItKit

@Suite("RecipeDeduplicator")
struct RecipeDeduplicatorTests {
    @Test func deduplicatesBySourceURLBeforeID() {
        let sourceURL = URL(string: "https://example.com/same")!
        let recipes = [
            Recipe(id: "first", title: "First", blurb: "", cookingMinutes: 10, ingredients: ["egg"], sourceURL: sourceURL),
            Recipe(id: "second", title: "Second", blurb: "", cookingMinutes: 12, ingredients: ["egg"], sourceURL: sourceURL),
            Recipe(id: "second", title: "Second ID Duplicate", blurb: "", cookingMinutes: 12, ingredients: ["egg"])
        ]

        let result = RecipeDeduplicator().deduplicate(recipes)

        #expect(result.map(\.id) == ["first", "second"])
    }
}
