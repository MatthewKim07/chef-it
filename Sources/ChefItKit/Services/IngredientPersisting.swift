import Foundation

/// Storage boundary for the ingredient board. Lets the store stay
/// platform-agnostic (UserDefaults today, SwiftData/iCloud later) and lets
/// tests inject an in-memory implementation.
public protocol IngredientPersisting: Sendable {
    func load() throws -> [Ingredient]
    func save(_ ingredients: [Ingredient]) throws
}

public enum IngredientPersistenceError: Error, Sendable {
    case decodingFailed
    case encodingFailed
}

/// In-memory persister, useful in tests and previews.
public final class InMemoryIngredientPersister: IngredientPersisting, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [Ingredient]

    public init(_ initial: [Ingredient] = []) {
        self.stored = initial
    }

    public func load() throws -> [Ingredient] {
        lock.lock(); defer { lock.unlock() }
        return stored
    }

    public func save(_ ingredients: [Ingredient]) throws {
        lock.lock(); defer { lock.unlock() }
        stored = ingredients
    }
}

/// `UserDefaults`-backed persister. Stores a JSON-encoded `[Ingredient]` blob
/// under a single key. Designed to be replaceable: SwiftData or a server-sync
/// implementation can adopt the same protocol.
///
/// Marked `@unchecked Sendable` because `UserDefaults` itself is documented
/// thread-safe; the persister holds no other mutable state.
public final class UserDefaultsIngredientPersister: IngredientPersisting, @unchecked Sendable {
    public let defaults: UserDefaults
    public let key: String

    public init(
        defaults: UserDefaults = .standard,
        key: String = "ChefIt.IngredientBoard.v1"
    ) {
        self.defaults = defaults
        self.key = key
    }

    public func load() throws -> [Ingredient] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([Ingredient].self, from: data)
        } catch {
            throw IngredientPersistenceError.decodingFailed
        }
    }

    public func save(_ ingredients: [Ingredient]) throws {
        do {
            let data = try JSONEncoder().encode(ingredients)
            defaults.set(data, forKey: key)
        } catch {
            throw IngredientPersistenceError.encodingFailed
        }
    }
}
