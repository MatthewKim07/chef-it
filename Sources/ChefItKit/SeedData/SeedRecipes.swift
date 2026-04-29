import Foundation

public enum SeedRecipes {
    public static let all: [Recipe] = [
        Recipe(
            id: "garlic-oil-pasta",
            title: "Garlic Oil Pasta",
            blurb: "Five-ingredient weeknight default.",
            cookingMinutes: 15,
            servings: 2,
            cuisine: "Italian",
            difficulty: .easy,
            ingredients: ["pasta", "garlic", "olive oil", "salt"],
            dietaryTags: ["vegetarian"]
        ),
        Recipe(
            id: "tomato-egg-stir",
            title: "Tomato & Egg Stir-fry",
            blurb: "Soft scramble, sweet tomato, over rice.",
            cookingMinutes: 12,
            servings: 2,
            cuisine: "Chinese",
            difficulty: .easy,
            ingredients: ["egg", "tomato", "salt", "rice"],
            dietaryTags: ["vegetarian"]
        ),
        Recipe(
            id: "lemon-chicken",
            title: "Skillet Lemon Chicken",
            blurb: "Crispy edges, bright pan sauce.",
            cookingMinutes: 25,
            servings: 2,
            cuisine: "Mediterranean",
            difficulty: .medium,
            ingredients: ["chicken", "lemon", "garlic", "olive oil", "salt"],
            dietaryTags: ["gluten-free"]
        ),
        Recipe(
            id: "miso-soup",
            title: "Quick Miso Soup",
            blurb: "Bowl-warming, pantry-driven.",
            cookingMinutes: 10,
            servings: 2,
            cuisine: "Japanese",
            difficulty: .easy,
            ingredients: ["miso", "tofu", "scallion"]
        ),
        Recipe(
            id: "black-bean-tacos",
            title: "Black Bean Tacos",
            blurb: "Crisp tortilla, smoky beans.",
            cookingMinutes: 18,
            servings: 2,
            cuisine: "Mexican",
            difficulty: .easy,
            ingredients: ["black beans", "tortilla", "lime", "cumin"],
            dietaryTags: ["vegan"]
        ),
        Recipe(
            id: "shrimp-scampi",
            title: "Shrimp Scampi",
            blurb: "Butter, garlic, lemon — the classic.",
            cookingMinutes: 20,
            servings: 2,
            cuisine: "Italian",
            difficulty: .easy,
            ingredients: ["shrimp", "garlic", "butter", "lemon", "pasta", "parsley"]
        ),
        Recipe(
            id: "salmon-rice-bowl",
            title: "Salmon Rice Bowl",
            blurb: "Crisp salmon, warm rice, soy-sesame drizzle.",
            cookingMinutes: 22,
            servings: 2,
            cuisine: "Japanese",
            difficulty: .easy,
            ingredients: ["salmon", "rice", "soy sauce", "scallion", "sesame oil"]
        )
    ]
}
