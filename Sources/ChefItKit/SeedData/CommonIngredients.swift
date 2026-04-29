import Foundation

/// Common-pantry suggestion source. Mirrors Pantry Pal's `commonIngredients`
/// dataset role: powers autocomplete during manual entry. Stays compact and
/// canonical — the normalizer handles raw input variants.
public enum CommonIngredients {
    public static let all: [String] = [
        // Produce
        "tomato", "onion", "scallion", "garlic", "ginger",
        "bell pepper", "jalapeño", "carrot", "celery", "potato",
        "sweet potato", "spinach", "kale", "lettuce", "broccoli",
        "cauliflower", "mushroom", "zucchini", "cucumber", "avocado",
        "lemon", "lime", "apple", "banana", "orange",
        // Protein
        "chicken", "beef", "pork", "turkey", "bacon",
        "salmon", "tuna", "cod", "shrimp", "tofu",
        "egg", "tempeh",
        // Dairy
        "milk", "butter", "cream", "yogurt", "sour cream",
        "cheddar", "mozzarella", "parmesan", "feta", "ricotta",
        "cream cheese",
        // Grains & bread
        "rice", "pasta", "bread", "tortilla", "quinoa", "oats",
        // Pantry / oils / sauces
        "olive oil", "vegetable oil", "sesame oil", "soy sauce",
        "vinegar", "honey", "mustard", "ketchup", "mayonnaise",
        "hot sauce", "miso",
        // Beans & legumes
        "black beans", "kidney beans", "chickpeas", "lentils",
        // Spices & herbs
        "salt", "black pepper", "red pepper flakes", "paprika",
        "cumin", "coriander", "turmeric", "cinnamon",
        "basil", "parsley", "cilantro", "oregano", "thyme", "rosemary"
    ]
}
