import Foundation

/// Normalizes free-form ingredient strings into canonical recipe-friendly names.
///
/// Mirrors Pantry Pal's two-stage approach: a static lookup map (e.g.
/// `"cherry tomatoes" → "tomato"`) plus lowercase/trim. The map here is a
/// production-quality starting set — milestones 2+ should expand it and add
/// fuzzy fallback (e.g. plural stripping, suffix folding).
public struct IngredientNormalizer: Sendable {
    private let lookup: [String: String]
    private let categoryHints: [String: IngredientCategory]

    public init(
        lookup: [String: String] = IngredientNormalizer.defaultLookup,
        categoryHints: [String: IngredientCategory] = IngredientNormalizer.defaultCategories
    ) {
        self.lookup = lookup
        self.categoryHints = categoryHints
    }

    public func canonicalize(_ raw: String) -> String {
        let cleaned = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return cleaned }
        if let hit = lookup[cleaned] { return hit }
        // Plural fallback: drop trailing 's' if base form is in lookup.
        if cleaned.hasSuffix("s") {
            let singular = String(cleaned.dropLast())
            if let hit = lookup[singular] { return hit }
            return singular
        }
        return cleaned
    }

    public func category(for canonical: String) -> IngredientCategory {
        categoryHints[canonical] ?? .other
    }

    public func parseList(_ raw: String) -> [String] {
        // Split on common delimiters (matches Pantry Pal: , ; | newline tab).
        let separators = CharacterSet(charactersIn: ",;|\n\t")
        return raw.components(separatedBy: separators)
            .map { canonicalize($0) }
            .filter { !$0.isEmpty }
    }
}

extension IngredientNormalizer {
    /// Seed lookup map. Subset of Pantry Pal's table — deliberately compact for
    /// milestone 1; expand in later milestones.
    public static let defaultLookup: [String: String] = [
        // Tomatoes
        "cherry tomatoes": "tomato",
        "roma tomatoes": "tomato",
        "grape tomatoes": "tomato",
        "diced tomatoes": "tomato",
        "tomatoes": "tomato",
        // Onions
        "yellow onion": "onion",
        "white onion": "onion",
        "red onion": "onion",
        "green onion": "scallion",
        "spring onion": "scallion",
        "scallions": "scallion",
        // Garlic
        "fresh garlic": "garlic",
        "garlic cloves": "garlic",
        "minced garlic": "garlic",
        // Peppers
        "red bell pepper": "bell pepper",
        "green bell pepper": "bell pepper",
        "bell peppers": "bell pepper",
        // Greens
        "baby spinach": "spinach",
        "fresh spinach": "spinach",
        "romaine lettuce": "lettuce",
        "iceberg lettuce": "lettuce",
        // Proteins
        "chicken breast": "chicken",
        "chicken thighs": "chicken",
        "chicken thigh": "chicken",
        "rotisserie chicken": "chicken",
        "ground beef": "beef",
        "beef mince": "beef",
        "ground pork": "pork",
        "pork chop": "pork",
        "salmon fillet": "salmon",
        "tuna steak": "tuna",
        "jumbo shrimp": "shrimp",
        "prawns": "shrimp",
        "eggs": "egg",
        // Dairy
        "whole milk": "milk",
        "skim milk": "milk",
        "heavy cream": "cream",
        "heavy whipping cream": "cream",
        "salted butter": "butter",
        "unsalted butter": "butter",
        "shredded mozzarella": "mozzarella",
        "fresh mozzarella": "mozzarella",
        "parmesan cheese": "parmesan",
        "grated parmesan": "parmesan",
        "greek yogurt": "yogurt",
        // Grains
        "white rice": "rice",
        "brown rice": "rice",
        "jasmine rice": "rice",
        "spaghetti": "pasta",
        "penne": "pasta",
        "linguine": "pasta",
        "fettuccine": "pasta",
        "macaroni": "pasta",
        // Pantry
        "extra virgin olive oil": "olive oil",
        "evoo": "olive oil",
        "kosher salt": "salt",
        "sea salt": "salt",
        "ground black pepper": "black pepper",
        "black peppercorns": "black pepper",
        "chili flakes": "red pepper flakes",
        "crushed red pepper": "red pepper flakes",
        // Citrus
        "fresh lemon": "lemon",
        "meyer lemon": "lemon",
        "fresh lime": "lime",
        // Herbs
        "fresh basil": "basil",
        "dried basil": "basil",
        "fresh parsley": "parsley",
        "italian parsley": "parsley",
        "fresh cilantro": "cilantro"
    ]

    public static let defaultCategories: [String: IngredientCategory] = [
        "tomato": .produce, "onion": .produce, "scallion": .produce,
        "garlic": .produce, "bell pepper": .produce, "spinach": .produce,
        "lettuce": .produce, "lemon": .produce, "lime": .produce,
        "chicken": .protein, "beef": .protein, "pork": .protein,
        "salmon": .protein, "tuna": .protein, "shrimp": .protein, "egg": .protein,
        "milk": .dairy, "cream": .dairy, "butter": .dairy,
        "mozzarella": .dairy, "parmesan": .dairy, "yogurt": .dairy,
        "rice": .grain, "pasta": .grain,
        "olive oil": .pantry, "salt": .pantry, "black pepper": .spice,
        "red pepper flakes": .spice,
        "basil": .spice, "parsley": .spice, "cilantro": .spice
    ]
}
