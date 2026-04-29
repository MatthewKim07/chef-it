import Foundation

/// Local recipe corpus for the matching MVP. Sized to cover the manual-test
/// pantry inputs in MILESTONES.md M3 with believable variety; deliberately
/// not exhaustive — replaced wholesale by a real recipe API in M5.
public enum SeedRecipes {
    public static let all: [Recipe] = [
        // Pasta-leaning
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
            id: "tomato-garlic-pasta",
            title: "Tomato-Garlic Pasta",
            blurb: "Quick stovetop sauce, cracked pepper finish.",
            cookingMinutes: 20,
            servings: 2,
            cuisine: "Italian",
            difficulty: .easy,
            ingredients: ["pasta", "tomato", "garlic", "olive oil", "salt"],
            dietaryTags: ["vegetarian"]
        ),
        Recipe(
            id: "marinara-base",
            title: "Stovetop Marinara",
            blurb: "Pan sauce. Tomato, garlic, oil — that's it.",
            cookingMinutes: 18,
            servings: 4,
            cuisine: "Italian",
            difficulty: .easy,
            ingredients: ["tomato", "garlic", "olive oil", "salt"],
            dietaryTags: ["vegan", "vegetarian"]
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
            id: "cacio-e-pepe",
            title: "Cacio e Pepe",
            blurb: "Pasta. Pecorino. Pepper.",
            cookingMinutes: 18,
            servings: 2,
            cuisine: "Italian",
            difficulty: .medium,
            ingredients: ["pasta", "parmesan", "black pepper", "salt"],
            dietaryTags: ["vegetarian"]
        ),

        // Egg / rice / breakfast-y
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
            id: "fried-rice",
            title: "Weeknight Fried Rice",
            blurb: "Cold rice + hot pan + scrambled egg.",
            cookingMinutes: 15,
            servings: 2,
            cuisine: "Chinese",
            difficulty: .easy,
            ingredients: ["rice", "egg", "scallion", "soy sauce", "garlic"]
        ),
        Recipe(
            id: "soft-scramble",
            title: "Slow Soft Scramble",
            blurb: "Low heat, butter finish, salt last.",
            cookingMinutes: 10,
            servings: 1,
            cuisine: "American",
            difficulty: .easy,
            ingredients: ["egg", "butter", "salt"],
            dietaryTags: ["vegetarian", "gluten-free"]
        ),

        // Chicken
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
            id: "garlic-chicken-rice",
            title: "Garlic Chicken Rice",
            blurb: "One-pan chicken, garlic, jammy rice.",
            cookingMinutes: 30,
            servings: 2,
            cuisine: "Mediterranean",
            difficulty: .medium,
            ingredients: ["chicken", "garlic", "rice", "olive oil", "salt"],
            dietaryTags: ["gluten-free"]
        ),

        // Salmon / fish
        Recipe(
            id: "salmon-rice-bowl",
            title: "Salmon Rice Bowl",
            blurb: "Crisp salmon, warm rice, soy-sesame drizzle.",
            cookingMinutes: 22,
            servings: 2,
            cuisine: "Japanese",
            difficulty: .easy,
            ingredients: ["salmon", "rice", "soy sauce", "scallion", "sesame oil"]
        ),

        // Tofu / Asian
        Recipe(
            id: "miso-soup",
            title: "Quick Miso Soup",
            blurb: "Bowl-warming, pantry-driven.",
            cookingMinutes: 10,
            servings: 2,
            cuisine: "Japanese",
            difficulty: .easy,
            ingredients: ["miso", "tofu", "scallion"],
            dietaryTags: ["vegan", "vegetarian"]
        ),
        Recipe(
            id: "tofu-stirfry",
            title: "Crispy Tofu Stir-fry",
            blurb: "Sear hard, sauce light.",
            cookingMinutes: 20,
            servings: 2,
            cuisine: "Chinese",
            difficulty: .easy,
            ingredients: ["tofu", "scallion", "garlic", "soy sauce", "rice"],
            dietaryTags: ["vegan", "vegetarian"]
        ),

        // Mexican / beans
        Recipe(
            id: "black-bean-tacos",
            title: "Black Bean Tacos",
            blurb: "Crisp tortilla, smoky beans.",
            cookingMinutes: 18,
            servings: 2,
            cuisine: "Mexican",
            difficulty: .easy,
            ingredients: ["black beans", "tortilla", "lime", "cumin"],
            dietaryTags: ["vegan", "vegetarian"]
        ),

        // Veg snacks
        Recipe(
            id: "tomato-bruschetta",
            title: "Tomato Bruschetta",
            blurb: "Toasted bread, smashed garlic, ripe tomato.",
            cookingMinutes: 12,
            servings: 2,
            cuisine: "Italian",
            difficulty: .easy,
            ingredients: ["bread", "tomato", "garlic", "olive oil", "basil"],
            dietaryTags: ["vegetarian"]
        ),

        // Beef
        Recipe(
            id: "beef-tacos",
            title: "Ground Beef Tacos",
            blurb: "Spiced beef, charred tortilla, lime.",
            cookingMinutes: 20,
            servings: 3,
            cuisine: "Mexican",
            difficulty: .easy,
            ingredients: ["beef", "tortilla", "onion", "cumin", "lime"]
        ),

        // Soup
        Recipe(
            id: "chicken-soup",
            title: "Brothy Chicken Soup",
            blurb: "Stock, chicken, scallion, rice.",
            cookingMinutes: 35,
            servings: 4,
            cuisine: "American",
            difficulty: .easy,
            ingredients: ["chicken", "scallion", "rice", "salt", "garlic"],
            dietaryTags: ["gluten-free"]
        )
    ]
}
