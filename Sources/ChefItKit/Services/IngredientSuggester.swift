import Foundation

/// Provides autocomplete suggestions for manual entry. Behavior mirrors
/// Pantry Pal: filter common ingredients by case-insensitive substring,
/// excluding items already on the board.
public struct IngredientSuggester: Sendable {
    public let pool: [String]
    public let limit: Int

    public init(pool: [String] = CommonIngredients.all, limit: Int = 6) {
        self.pool = pool
        self.limit = limit
    }

    public func suggestions(for query: String, excluding canonicals: Set<String>) -> [String] {
        let trimmed = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        var results: [String] = []
        for candidate in pool {
            if canonicals.contains(candidate) { continue }
            if candidate.contains(trimmed) {
                results.append(candidate)
                if results.count == limit { break }
            }
        }
        return results
    }
}
