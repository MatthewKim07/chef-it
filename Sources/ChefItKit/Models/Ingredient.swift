import Foundation

public struct Ingredient: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public let canonicalName: String
    public let category: IngredientCategory
    public let source: IngredientSource
    public let addedAt: Date
    public let quantity: Double
    public let quantityUnit: IngredientQuantityUnit
    public let expiresAt: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        canonicalName: String,
        category: IngredientCategory = .other,
        source: IngredientSource = .manual,
        addedAt: Date = Date(),
        quantity: Double = 1,
        quantityUnit: IngredientQuantityUnit = .item,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.canonicalName = canonicalName
        self.category = category
        self.source = source
        self.addedAt = addedAt
        self.quantity = max(0.1, quantity)
        self.quantityUnit = quantityUnit
        self.expiresAt = expiresAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case canonicalName
        case category
        case source
        case addedAt
        case quantity
        case quantityUnit
        case expiresAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        canonicalName = try container.decode(String.self, forKey: .canonicalName)
        category = try container.decodeIfPresent(IngredientCategory.self, forKey: .category) ?? .other
        source = try container.decodeIfPresent(IngredientSource.self, forKey: .source) ?? .manual
        addedAt = try container.decodeIfPresent(Date.self, forKey: .addedAt) ?? Date()
        quantity = max(0.1, try container.decodeIfPresent(Double.self, forKey: .quantity) ?? 1)
        quantityUnit = try container.decodeIfPresent(IngredientQuantityUnit.self, forKey: .quantityUnit) ?? .item
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(canonicalName, forKey: .canonicalName)
        try container.encode(category, forKey: .category)
        try container.encode(source, forKey: .source)
        try container.encode(addedAt, forKey: .addedAt)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(quantityUnit, forKey: .quantityUnit)
        try container.encode(expiresAt, forKey: .expiresAt)
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

public enum IngredientQuantityUnit: String, Codable, CaseIterable, Sendable {
    case item
    case gram
    case kilogram
    case ounce
    case pound
    case milliliter
    case liter
    case cup
    case tablespoon
    case teaspoon

    public var label: String {
        switch self {
        case .item: return "pcs"
        case .gram: return "g"
        case .kilogram: return "kg"
        case .ounce: return "oz"
        case .pound: return "lb"
        case .milliliter: return "ml"
        case .liter: return "L"
        case .cup: return "cup"
        case .tablespoon: return "tbsp"
        case .teaspoon: return "tsp"
        }
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
