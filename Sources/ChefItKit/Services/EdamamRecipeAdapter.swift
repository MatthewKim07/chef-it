import Foundation

public struct EdamamRecipeAdapter: Sendable {
    public init() {}

    func adapt(_ recipe: EdamamRecipe) -> Recipe {
        let ingredients = adaptedIngredients(from: recipe)
        let cookingMinutes = adaptedCookingMinutes(recipe.totalTime)
        let cuisine = recipe.cuisineType?.first?.capitalized ?? "International"
        let servings = max(1, Int((recipe.yield ?? 2).rounded()))

        return Recipe(
            id: adaptedID(from: recipe.uri),
            title: recipe.label,
            blurb: adaptedBlurb(
                label: recipe.label,
                cuisine: cuisine,
                calories: recipe.calories,
                servings: servings
            ),
            cookingMinutes: cookingMinutes,
            servings: servings,
            cuisine: cuisine,
            difficulty: adaptedDifficulty(cookingMinutes),
            ingredients: ingredients,
            dietaryTags: adaptedDietaryTags(recipe),
            imageURL: adaptedImageURL(recipe),
            sourceURL: recipe.url
        )
    }

    func adapt(_ response: EdamamSearchResponse) -> [Recipe] {
        response.hits.map { adapt($0.recipe) }
    }

    private func adaptedID(from uri: String) -> String {
        if let range = uri.range(of: "#recipe_") {
            return String(uri[range.upperBound...])
        }
        return uri
    }

    private func adaptedIngredients(from recipe: EdamamRecipe) -> [String] {
        let foods = recipe.ingredients?
            .compactMap { $0.food ?? $0.text }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []

        if !foods.isEmpty {
            return Array(NSOrderedSet(array: foods).compactMap { $0 as? String })
        }

        return recipe.ingredientLines?
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []
    }

    private func adaptedCookingMinutes(_ totalTime: Double?) -> Int {
        guard let totalTime, totalTime > 0 else { return 30 }
        return max(1, Int(totalTime.rounded()))
    }

    private func adaptedDifficulty(_ cookingMinutes: Int) -> Difficulty {
        if cookingMinutes > 60 { return .hard }
        if cookingMinutes > 30 { return .medium }
        return .easy
    }

    private func adaptedDietaryTags(_ recipe: EdamamRecipe) -> [String] {
        let labels = (recipe.healthLabels ?? []) + (recipe.dietLabels ?? [])
        let lowercased = Set(labels.map { $0.lowercased() })
        var tags: [String] = []

        if lowercased.contains("vegan") { tags.append("vegan") }
        if lowercased.contains("vegetarian") { tags.append("vegetarian") }
        if lowercased.contains("gluten-free") { tags.append("gluten-free") }
        if lowercased.contains("dairy-free") { tags.append("dairy-free") }
        if lowercased.contains("paleo") { tags.append("paleo") }
        if lowercased.contains("keto-friendly") { tags.append("keto") }

        return tags
    }

    private func adaptedImageURL(_ recipe: EdamamRecipe) -> URL? {
        recipe.images?["REGULAR"]?.url
            ?? recipe.images?["SMALL"]?.url
            ?? recipe.images?["THUMBNAIL"]?.url
            ?? recipe.image
    }

    private func adaptedBlurb(
        label: String,
        cuisine: String,
        calories: Double?,
        servings: Int
    ) -> String {
        guard let calories, servings > 0 else {
            return "\(label) from a \(cuisine.lowercased()) recipe source."
        }

        let perServing = Int((calories / Double(servings)).rounded())
        return "\(label) from a \(cuisine.lowercased()) recipe source, about \(perServing) calories per serving."
    }
}
