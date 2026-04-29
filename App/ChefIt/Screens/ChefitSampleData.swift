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

    static let detectedIngredients: [(String, String)] = [
        ("🍅", "Tomato"),
        ("🥛", "Milk"),
        ("🧅", "Onion"),
        ("🥦", "Broccoli"),
        ("🍗", "Chicken"),
        ("🧄", "Garlic"),
        ("🍝", "Pasta"),
        ("🥚", "Eggs")
    ]

    static let shoppingToBuy: [String] = [
        "Parmesan Cheese",
        "Olive Oil",
        "Basil",
        "Bread"
    ]

    static let shoppingPantry: [String] = [
        "Salt",
        "Pepper",
        "Milk"
    ]

    static let communityPosts: [(user: String, time: String, caption: String, imageURL: URL?, likes: Int, comments: Int)] = [
        (
            "kitchen.with.love",
            "2h",
            "Made Creamy Tomato Pasta 😍 So easy and delicious! #dinner #quickmeals",
            URL(string: "https://source.unsplash.com/400x300/?tomato,pasta,dinner"),
            125,
            28
        ),
        (
            "happy.cooking",
            "4h",
            "Perfect weeknight meal! #healthy #veggies",
            URL(string: "https://source.unsplash.com/400x300/?veggie,stirfry"),
            89,
            14
        ),
        (
            "chefmood.daily",
            "6h",
            "Tonight's cozy bowl turned out amazing #comfortfood",
            URL(string: "https://source.unsplash.com/400x300/?comfort,food"),
            76,
            11
        ),
        (
            "mealmagic",
            "8h",
            "Simple ingredients, big flavor ✨ #homecooking",
            URL(string: "https://source.unsplash.com/400x300/?home,cooking"),
            63,
            9
        )
    ]
}
