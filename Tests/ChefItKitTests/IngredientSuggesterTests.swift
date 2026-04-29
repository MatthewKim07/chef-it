import Testing
@testable import ChefItKit

@Suite("IngredientSuggester")
struct IngredientSuggesterTests {
    let suggester = IngredientSuggester(pool: ["tomato", "tortilla", "tofu", "garlic", "ginger"], limit: 3)

    @Test func emptyQueryReturnsNothing() {
        #expect(suggester.suggestions(for: "", excluding: []) == [])
        #expect(suggester.suggestions(for: "   ", excluding: []) == [])
    }

    @Test func substringMatch() {
        let s = suggester.suggestions(for: "to", excluding: [])
        #expect(s == ["tomato", "tortilla", "tofu"])
    }

    @Test func excludesAlreadyOnBoard() {
        let s = suggester.suggestions(for: "to", excluding: ["tomato"])
        #expect(s == ["tortilla", "tofu"])
    }

    @Test func caseInsensitive() {
        let s = suggester.suggestions(for: "GAR", excluding: [])
        #expect(s == ["garlic"])
    }

    @Test func limitRespected() {
        let big = IngredientSuggester(pool: Array(repeating: "tomato", count: 20), limit: 4)
        // All identical; limit caps results.
        let s = big.suggestions(for: "tom", excluding: [])
        #expect(s.count == 4)
    }
}
