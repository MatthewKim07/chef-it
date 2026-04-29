import Foundation

public protocol FavoriteRecipePersisting: Sendable {
    func load() throws -> Set<String>
    func save(_ recipeIDs: Set<String>) throws
}

public enum FavoriteRecipePersistenceError: Error, Sendable {
    case decodingFailed
    case encodingFailed
}

public final class InMemoryFavoriteRecipePersister: FavoriteRecipePersisting, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Set<String>

    public init(_ initial: Set<String> = []) {
        self.stored = initial
    }

    public func load() throws -> Set<String> {
        lock.lock(); defer { lock.unlock() }
        return stored
    }

    public func save(_ recipeIDs: Set<String>) throws {
        lock.lock(); defer { lock.unlock() }
        stored = recipeIDs
    }
}

public final class UserDefaultsFavoriteRecipePersister: FavoriteRecipePersisting, @unchecked Sendable {
    public let defaults: UserDefaults
    public let key: String

    public init(
        defaults: UserDefaults = .standard,
        key: String = "ChefIt.FavoriteRecipes.v1"
    ) {
        self.defaults = defaults
        self.key = key
    }

    public func load() throws -> Set<String> {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode(Set<String>.self, from: data)
        } catch {
            throw FavoriteRecipePersistenceError.decodingFailed
        }
    }

    public func save(_ recipeIDs: Set<String>) throws {
        do {
            let data = try JSONEncoder().encode(recipeIDs)
            defaults.set(data, forKey: key)
        } catch {
            throw FavoriteRecipePersistenceError.encodingFailed
        }
    }
}

public final class FavoriteRecipeStore: @unchecked Sendable {
    private let lock = NSLock()
    private let persister: any FavoriteRecipePersisting
    private var ids: Set<String>

    public init(persister: any FavoriteRecipePersisting = UserDefaultsFavoriteRecipePersister()) {
        self.persister = persister
        self.ids = (try? persister.load()) ?? []
    }

    public var favoriteRecipeIDs: Set<String> {
        lock.lock(); defer { lock.unlock() }
        return ids
    }

    public func isFavorite(_ recipeID: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return ids.contains(recipeID)
    }

    @discardableResult
    public func toggle(_ recipeID: String) -> Bool {
        lock.lock()
        let isFavorite: Bool
        if ids.contains(recipeID) {
            ids.remove(recipeID)
            isFavorite = false
        } else {
            ids.insert(recipeID)
            isFavorite = true
        }
        let snapshot = ids
        lock.unlock()

        try? persister.save(snapshot)
        return isFavorite
    }
}
