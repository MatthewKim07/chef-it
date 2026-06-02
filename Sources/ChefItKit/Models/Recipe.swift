import Foundation

public struct Recipe: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let title: String
    public let blurb: String
    public let cookingMinutes: Int
    public let servings: Int
    public let cuisine: String
    public let difficulty: Difficulty
    public let ingredients: [String]
    public let dietaryTags: [String]
    public let imageURL: URL?
    public let sourceURL: URL?
    /// TheMealDB category string (e.g. "Breakfast", "Chicken"). Empty = untagged, no meal-time restriction.
    public let mealCategory: String
    /// Full cooking instructions from the recipe source.
    public let instructions: String

    public init(
        id: String,
        title: String,
        blurb: String,
        cookingMinutes: Int,
        servings: Int = 2,
        cuisine: String = "",
        difficulty: Difficulty = .easy,
        ingredients: [String],
        dietaryTags: [String] = [],
        imageURL: URL? = nil,
        sourceURL: URL? = nil,
        mealCategory: String = "",
        instructions: String = ""
    ) {
        self.id = id
        self.title = title
        self.blurb = blurb
        self.cookingMinutes = cookingMinutes
        self.servings = servings
        self.cuisine = cuisine
        self.difficulty = difficulty
        self.ingredients = ingredients
        self.dietaryTags = dietaryTags
        self.imageURL = imageURL
        self.sourceURL = sourceURL
        self.mealCategory = mealCategory
        self.instructions = instructions
    }
}

public enum Difficulty: String, Codable, CaseIterable, Sendable {
    case easy
    case medium
    case hard
}
