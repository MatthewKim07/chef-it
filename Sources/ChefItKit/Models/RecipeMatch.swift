import Foundation

public struct RecipeMatch: Identifiable, Hashable, Sendable {
    public var id: String { recipe.id }
    public let recipe: Recipe
    public let matchedIngredients: [String]
    public let missingIngredients: [String]
    public let coverage: Double
    public let status: MatchStatus
    public let score: Double
    public let rationale: [String]

    public init(
        recipe: Recipe,
        matchedIngredients: [String],
        missingIngredients: [String],
        coverage: Double,
        status: MatchStatus,
        score: Double = 0,
        rationale: [String] = []
    ) {
        self.recipe = recipe
        self.matchedIngredients = matchedIngredients
        self.missingIngredients = missingIngredients
        self.coverage = coverage
        self.status = status
        self.score = score
        self.rationale = rationale
    }

    /// Coverage as a 0–100 integer, useful for compact UI display.
    public var coveragePercent: Int {
        Int((coverage * 100).rounded())
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
