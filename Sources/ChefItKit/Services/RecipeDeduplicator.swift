import Foundation

public struct RecipeDeduplicator: Sendable {
    public init() {}

    public func deduplicate(_ recipes: [Recipe]) -> [Recipe] {
        var seen: Set<String> = []
        var unique: [Recipe] = []

        for recipe in recipes {
            let key = dedupeKey(for: recipe)
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            unique.append(recipe)
        }

        return unique
    }

    private func dedupeKey(for recipe: Recipe) -> String {
        if let sourceURL = recipe.sourceURL {
            return "source:\(sourceURL.absoluteString.lowercased())"
        }

        return "id:\(recipe.id.lowercased())"
    }
}
