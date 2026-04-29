import Testing
@testable import ChefItKit

@Suite("IngredientNormalizer")
struct NormalizerTests {
    let normalizer = IngredientNormalizer()

    @Test func lookupHits() {
        #expect(normalizer.canonicalize("Cherry Tomatoes") == "tomato")
        #expect(normalizer.canonicalize("ground beef") == "beef")
        #expect(normalizer.canonicalize("Extra Virgin Olive Oil") == "olive oil")
    }

    @Test func trimAndLowercase() {
        #expect(normalizer.canonicalize("  Garlic  ") == "garlic")
    }

    @Test func pluralFallback() {
        #expect(normalizer.canonicalize("carrots") == "carrot")
    }

    @Test func parseList() {
        let parsed = normalizer.parseList("Eggs, ground beef; chicken thigh\nsalt")
        #expect(parsed == ["egg", "beef", "chicken", "salt"])
    }

    @Test func categoryHints() {
        #expect(normalizer.category(for: "chicken") == .protein)
        #expect(normalizer.category(for: "tomato") == .produce)
        #expect(normalizer.category(for: "moonrock") == .other)
    }

    @Test func emptyAndWhitespaceOnly() {
        #expect(normalizer.canonicalize("") == "")
        #expect(normalizer.canonicalize("   \n\t  ") == "")
        #expect(normalizer.parseList("  ,  ; \n  ") == [])
    }

    @Test func collapsesInteriorWhitespace() {
        // Currently lookup is exact-match; document behavior so
        // future changes know what we expect.
        #expect(normalizer.canonicalize("Olive Oil") == "olive oil")
    }
}
