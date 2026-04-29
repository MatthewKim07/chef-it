import XCTest
@testable import ChefItKit

final class NormalizerTests: XCTestCase {
    let normalizer = IngredientNormalizer()

    func testLookupHits() {
        XCTAssertEqual(normalizer.canonicalize("Cherry Tomatoes"), "tomato")
        XCTAssertEqual(normalizer.canonicalize("ground beef"), "beef")
        XCTAssertEqual(normalizer.canonicalize("Extra Virgin Olive Oil"), "olive oil")
    }

    func testTrimAndLowercase() {
        XCTAssertEqual(normalizer.canonicalize("  Garlic  "), "garlic")
    }

    func testPluralFallback() {
        XCTAssertEqual(normalizer.canonicalize("carrots"), "carrot")
    }

    func testParseList() {
        let parsed = normalizer.parseList("Eggs, ground beef; chicken thigh\nsalt")
        XCTAssertEqual(parsed, ["egg", "beef", "chicken", "salt"])
    }

    func testCategoryHints() {
        XCTAssertEqual(normalizer.category(for: "chicken"), .protein)
        XCTAssertEqual(normalizer.category(for: "tomato"), .produce)
        XCTAssertEqual(normalizer.category(for: "moonrock"), .other)
    }
}
