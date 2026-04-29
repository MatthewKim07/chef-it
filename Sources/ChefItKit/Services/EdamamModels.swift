import Foundation

struct EdamamSearchResponse: Decodable, Sendable {
    let hits: [EdamamHit]
}

struct EdamamHit: Decodable, Sendable {
    let recipe: EdamamRecipe
}

struct EdamamRecipe: Decodable, Sendable {
    struct ImageVariant: Decodable, Sendable {
        let url: URL?
    }

    let uri: String
    let label: String
    let image: URL?
    let images: [String: ImageVariant]?
    let url: URL?
    let yield: Double?
    let dietLabels: [String]?
    let healthLabels: [String]?
    let ingredientLines: [String]?
    let ingredients: [EdamamIngredient]?
    let calories: Double?
    let totalTime: Double?
    let cuisineType: [String]?
}

struct EdamamIngredient: Decodable, Sendable {
    let text: String?
    let food: String?
}
