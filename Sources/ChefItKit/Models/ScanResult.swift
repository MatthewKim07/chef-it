import Foundation

public struct ScanResult: Hashable, Codable, Sendable {
    public let detectedAt: Date
    public let candidates: [DetectedIngredient]

    public init(detectedAt: Date = Date(), candidates: [DetectedIngredient]) {
        self.detectedAt = detectedAt
        self.candidates = candidates
    }
}

public struct DetectedIngredient: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let rawName: String
    public let canonicalName: String
    public let category: IngredientCategory
    public let confidence: Double

    public init(
        id: UUID = UUID(),
        rawName: String,
        canonicalName: String,
        category: IngredientCategory = .other,
        confidence: Double
    ) {
        self.id = id
        self.rawName = rawName
        self.canonicalName = canonicalName
        self.category = category
        self.confidence = confidence
    }
}
