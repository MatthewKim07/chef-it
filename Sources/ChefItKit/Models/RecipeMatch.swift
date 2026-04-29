import Foundation

public struct RecipeMatch: Identifiable, Hashable, Sendable {
    public var id: String { recipe.id }
    public let recipe: Recipe
    public let matchedIngredients: [String]
    public let missingIngredients: [String]
    public let coverage: Double
    public let status: MatchStatus

    public init(
        recipe: Recipe,
        matchedIngredients: [String],
        missingIngredients: [String],
        coverage: Double,
        status: MatchStatus
    ) {
        self.recipe = recipe
        self.matchedIngredients = matchedIngredients
        self.missingIngredients = missingIngredients
        self.coverage = coverage
        self.status = status
    }
}

public enum MatchStatus: String, Sendable {
    case ready
    case almost
    case excluded
}

public struct MatchResults: Sendable {
    public let ready: [RecipeMatch]
    public let almost: [RecipeMatch]

    public init(ready: [RecipeMatch], almost: [RecipeMatch]) {
        self.ready = ready
        self.almost = almost
    }

    public static let empty = MatchResults(ready: [], almost: [])
}
