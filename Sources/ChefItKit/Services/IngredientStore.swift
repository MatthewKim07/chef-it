import Foundation

public enum IngredientAddOutcome: Equatable, Sendable {
    case added(Ingredient)
    case duplicate(existingID: Ingredient.ID)
    case empty
}

public enum IngredientRenameOutcome: Equatable, Sendable {
    case renamed(Ingredient)
    case unchanged
    case empty
    case notFound
    case wouldDuplicate(existingID: Ingredient.ID)
}

/// Ingredient board with deduplication by canonical name and pluggable
/// persistence. Hot path stays in-memory; persister sees the latest snapshot
/// after each mutation.
@MainActor
public final class IngredientStore: ObservableObject {
    @Published public private(set) var ingredients: [Ingredient] = []

    private let normalizer: IngredientNormalizer
    private let persister: IngredientPersisting
    private var hasLoaded = false

    public init(
        normalizer: IngredientNormalizer = IngredientNormalizer(),
        persister: IngredientPersisting = InMemoryIngredientPersister()
    ) {
        self.normalizer = normalizer
        self.persister = persister
        loadFromPersister()
    }

    private func loadFromPersister() {
        guard !hasLoaded else { return }
        hasLoaded = true
        if let loaded = try? persister.load() {
            ingredients = loaded
        }
    }

    private func persist() {
        try? persister.save(ingredients)
    }

    public var canonicalSet: Set<String> {
        Set(ingredients.map(\.canonicalName))
    }

    @discardableResult
    public func add(rawName: String, source: IngredientSource = .manual) -> IngredientAddOutcome {
        let canonical = normalizer.canonicalize(rawName)
        guard !canonical.isEmpty else { return .empty }
        if let existing = ingredients.first(where: { $0.canonicalName == canonical }) {
            return .duplicate(existingID: existing.id)
        }
        let category = normalizer.category(for: canonical)
        let ingredient = Ingredient(
            name: rawName.trimmingCharacters(in: .whitespacesAndNewlines),
            canonicalName: canonical,
            category: category,
            source: source
        )
        ingredients.append(ingredient)
        persist()
        return .added(ingredient)
    }

    @discardableResult
    public func addMany(_ raws: [String], source: IngredientSource = .manual) -> [IngredientAddOutcome] {
        raws.map { add(rawName: $0, source: source) }
    }

    @discardableResult
    public func parseAndAdd(_ free: String, source: IngredientSource = .manual) -> [IngredientAddOutcome] {
        let parts = splitFreeForm(free)
        var results: [IngredientAddOutcome] = []
        for part in parts {
            results.append(add(rawName: part, source: source))
        }
        return results
    }

    /// Splits free-form input on Pantry Pal's delimiter set (`,;|\n\t`)
    /// **without** canonicalizing — so the original raw text becomes the
    /// display name and `add(rawName:)` does the canonicalization once.
    private func splitFreeForm(_ raw: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",;|\n\t")
        return raw.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    public func remove(_ id: Ingredient.ID) {
        ingredients.removeAll { $0.id == id }
        persist()
    }

    public func clear() {
        ingredients.removeAll()
        persist()
    }

    /// Restore a prior snapshot — used to back the "undo clear" affordance.
    public func restore(_ snapshot: [Ingredient]) {
        ingredients = snapshot
        persist()
    }

    /// Shared live store for the running app. Returns the same instance on
    /// every call so scan, recommendations, and pantry all observe one source
    /// of truth. Tests should construct their own store with InMemoryIngredientPersister.
    @MainActor
    public static func live() -> IngredientStore {
        LiveStore.shared
    }

    private enum LiveStore {
        @MainActor static let shared = IngredientStore(persister: UserDefaultsIngredientPersister())
    }

    /// Rename an existing ingredient. Re-runs canonicalization; if the new
    /// canonical collides with another ingredient, returns `.wouldDuplicate`
    /// without mutating state so the caller can offer a merge prompt.
    @discardableResult
    public func rename(_ id: Ingredient.ID, to newRawName: String) -> IngredientRenameOutcome {
        guard let index = ingredients.firstIndex(where: { $0.id == id }) else { return .notFound }
        let canonical = normalizer.canonicalize(newRawName)
        guard !canonical.isEmpty else { return .empty }
        let trimmed = newRawName.trimmingCharacters(in: .whitespacesAndNewlines)

        if canonical == ingredients[index].canonicalName, trimmed == ingredients[index].name {
            return .unchanged
        }

        if let collision = ingredients.first(where: { $0.canonicalName == canonical && $0.id != id }) {
            return .wouldDuplicate(existingID: collision.id)
        }

        let prior = ingredients[index]
        let updated = Ingredient(
            id: prior.id,
            name: trimmed,
            canonicalName: canonical,
            category: normalizer.category(for: canonical),
            source: prior.source,
            addedAt: prior.addedAt
        )
        ingredients[index] = updated
        persist()
        return .renamed(updated)
    }
}
