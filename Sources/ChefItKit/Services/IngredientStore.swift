import Foundation

/// In-memory ingredient store with deduplication by canonical name.
/// Persistence lands in milestone 2 (SwiftData or `UserDefaults`-backed
/// adapter). Marked `@MainActor` so SwiftUI views can hold it directly.
@MainActor
public final class IngredientStore: ObservableObject {
    @Published public private(set) var ingredients: [Ingredient] = []

    private let normalizer: IngredientNormalizer

    public init(normalizer: IngredientNormalizer = IngredientNormalizer()) {
        self.normalizer = normalizer
    }

    public var canonicalSet: Set<String> {
        Set(ingredients.map(\.canonicalName))
    }

    @discardableResult
    public func add(rawName: String, source: IngredientSource = .manual) -> Ingredient? {
        let canonical = normalizer.canonicalize(rawName)
        guard !canonical.isEmpty else { return nil }
        if canonicalSet.contains(canonical) { return nil }
        let category = normalizer.category(for: canonical)
        let ingredient = Ingredient(
            name: rawName.trimmingCharacters(in: .whitespacesAndNewlines),
            canonicalName: canonical,
            category: category,
            source: source
        )
        ingredients.append(ingredient)
        return ingredient
    }

    public func addMany(_ raws: [String], source: IngredientSource = .manual) {
        for raw in raws { add(rawName: raw, source: source) }
    }

    public func parseAndAdd(_ free: String, source: IngredientSource = .manual) {
        let names = normalizer.parseList(free)
        addMany(names, source: source)
    }

    public func remove(_ id: Ingredient.ID) {
        ingredients.removeAll { $0.id == id }
    }

    public func clear() {
        ingredients.removeAll()
    }
}
