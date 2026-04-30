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

    /// `(label, SF Symbol name)`
    static let ingredientChips: [(String, String)] = [
        ("Tomato", ChefitSymbol.tomato),
        ("Garlic", ChefitSymbol.garlic),
        ("Olive Oil", ChefitSymbol.oliveOil),
        ("Pasta", ChefitSymbol.pasta)
    ]

    /// `(SF Symbol name, ingredient name, quantity)`
    static let recipeDetailIngredients: [(String, String, String)] = [
        (ChefitSymbol.tomato, "Tomato", "2 pcs"),
        (ChefitSymbol.pasta, "Pasta", "200g"),
        (ChefitSymbol.garlic, "Garlic", "2 cloves"),
        (ChefitSymbol.oliveOil, "Olive Oil", "2 tbsp")
    ]

    /// Recipe-specific rows for discovery + cart missing-ingredient logic.
    static func ingredientRows(forRecipeId id: String) -> [(String, String, String)] {
        switch id {
        case "veggie-stir-fry":
            return [
                (ChefitSymbol.broccoli, "Broccoli", "1 head"),
                (ChefitSymbol.tomato, "Bell Pepper", "2"),
                (ChefitSymbol.garlic, "Garlic", "3 cloves"),
                (ChefitSymbol.oliveOil, "Sesame Oil", "1 tbsp")
            ]
        case "tomato-broccoli-pasta":
            return [
                (ChefitSymbol.tomato, "Tomato", "400g"),
                (ChefitSymbol.broccoli, "Broccoli", "200g"),
                (ChefitSymbol.pasta, "Pasta", "350g"),
                (ChefitSymbol.garlic, "Garlic", "2 cloves"),
                (ChefitSymbol.oliveOil, "Olive Oil", "3 tbsp")
            ]
        default:
            return recipeDetailIngredients
        }
    }

    static func ingredientDisplayNames(forRecipeId id: String) -> [String] {
        ingredientRows(forRecipeId: id).map(\.1)
    }

    /// `(label, SF Symbol)` chips for discovery horizontal strip.
    static func ingredientChips(forRecipeId id: String) -> [(String, String)] {
        ingredientRows(forRecipeId: id).map { ($0.1, $0.0) }
    }

    /// `(SF Symbol name, label)`
    static let detectedIngredients: [(String, String)] = [
        (ChefitSymbol.tomato, "Tomato"),
        (ChefitSymbol.milk, "Milk"),
        (ChefitSymbol.onion, "Onion"),
        (ChefitSymbol.broccoli, "Broccoli"),
        (ChefitSymbol.chicken, "Chicken"),
        (ChefitSymbol.garlic, "Garlic"),
        (ChefitSymbol.pasta, "Pasta"),
        (ChefitSymbol.egg, "Eggs")
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
            "Made Creamy Tomato Pasta — so easy and delicious! #dinner #quickmeals",
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
            "Simple ingredients, big flavor. #homecooking",
            URL(string: "https://source.unsplash.com/400x300/?home,cooking"),
            63,
            9
        )
    ]
}
