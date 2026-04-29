import Foundation

struct ChefitRecipeItem: Identifiable, Hashable {
    let id: String
    let title: String
    let imageURL: URL?
    let minutes: Int
    let difficulty: String
}

enum ChefitSampleData {
    static let popularRecipes: [ChefitRecipeItem] = [
        .init(
            id: "creamy-pasta",
            title: "Creamy Pasta",
            imageURL: URL(string: "https://source.unsplash.com/400x300/?creamy,pasta"),
            minutes: 20,
            difficulty: "Easy"
        ),
        .init(
            id: "veggie-stir-fry",
            title: "Veggie Stir Fry",
            imageURL: URL(string: "https://source.unsplash.com/400x300/?stir,fry"),
            minutes: 25,
            difficulty: "Easy"
        ),
        .init(
            id: "tomato-broccoli-pasta",
            title: "Tomato & Broccoli Pasta",
            imageURL: URL(string: "https://source.unsplash.com/400x300/?tomato,pasta"),
            minutes: 20,
            difficulty: "Medium"
        )
    ]

    static let ingredientChips: [(String, String)] = [
        ("Tomato", "🍅"),
        ("Garlic", "🧄"),
        ("Olive Oil", "🫒"),
        ("Pasta", "🍝")
    ]

    static let recipeDetailIngredients: [(String, String, String)] = [
        ("🍅", "Tomato", "2 pcs"),
        ("🍝", "Pasta", "200g"),
        ("🧄", "Garlic", "2 cloves"),
        ("🫒", "Olive Oil", "2 tbsp")
    ]
}
