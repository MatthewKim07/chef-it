import Foundation

public struct Ingredient: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public let canonicalName: String
    public let category: IngredientCategory
    public let source: IngredientSource
    public let addedAt: Date
    public let expiresAt: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        canonicalName: String,
        category: IngredientCategory = .other,
        source: IngredientSource = .manual,
        addedAt: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.canonicalName = canonicalName
        self.category = category
        self.source = source
        self.addedAt = addedAt
        self.expiresAt = expiresAt
    }

    /// Returns `1` when freshly added and trends toward `0` as it approaches expiry.
    /// `nil` means this ingredient has no explicit expiry metadata.
    public func freshness(now: Date = Date()) -> Double? {
        guard let expiresAt else { return nil }
        let total = expiresAt.timeIntervalSince(addedAt)
        guard total > 0 else { return 0 }
        let remaining = expiresAt.timeIntervalSince(now)
        return min(max(remaining / total, 0), 1)
    }
}

public enum IngredientSource: String, Codable, Sendable {
    case manual
    case scan
}

public enum IngredientCategory: String, Codable, CaseIterable, Sendable {
    case produce
    case protein
    case dairy
    case pantry
    case spice
    case grain
    case condiment
    case other
}
