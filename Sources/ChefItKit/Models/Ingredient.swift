import Foundation

public struct Ingredient: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public let canonicalName: String
    public let category: IngredientCategory
    public let source: IngredientSource
    public let addedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        canonicalName: String,
        category: IngredientCategory = .other,
        source: IngredientSource = .manual,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.canonicalName = canonicalName
        self.category = category
        self.source = source
        self.addedAt = addedAt
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
