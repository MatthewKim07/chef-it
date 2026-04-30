import ChefItKit
import Foundation

enum ShoppingListBuilder {
    /// Ingredients needed for the recipe that are not covered by pantry canonical names.
    static func missingIngredientDisplayNames(
        recipeIngredientNames: [String],
        pantryCanonical: Set<String>,
        normalizer: IngredientNormalizer = IngredientNormalizer()
    ) -> [String] {
        var picked: [String: String] = [:]
        for raw in recipeIngredientNames {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let canonical = normalizer.canonicalize(trimmed)
            guard !pantryCanonical.contains(canonical) else { continue }
            if picked[canonical] == nil {
                picked[canonical] = trimmed
            }
        }
        return picked.keys.sorted().compactMap { picked[$0] }
    }

    static func buildShoppingItems(
        from displayNames: [String],
        normalizer: IngredientNormalizer = IngredientNormalizer()
    ) -> [ShoppingItem] {
        displayNames.map { display in
            let canonical = normalizer.canonicalize(display)
            let cat = normalizer.category(for: canonical)
            return ShoppingItem(
                name: display,
                quantity: 1,
                isChecked: false,
                category: cat.rawValue,
                canonicalKey: canonical
            )
        }
    }

    /// Instacart search from unchecked items (what you still need to buy).
    static func instacartSearchURL(items: [ShoppingItem]) -> URL? {
        let names = items.filter { !$0.isChecked }.map(\.name)
        guard !names.isEmpty else { return nil }
        var components = URLComponents(string: "https://www.instacart.com/store/search")
        components?.queryItems = [
            URLQueryItem(name: "query", value: names.joined(separator: " "))
        ]
        return components?.url
    }

    static func categorySortIndex(_ raw: String?) -> Int {
        guard let raw else { return 99 }
        switch raw {
        case "produce": return 0
        case "dairy": return 1
        case "protein": return 2
        case "grain": return 3
        case "pantry": return 4
        case "spice": return 5
        case "condiment": return 6
        default: return 90
        }
    }

    static func sectionTitle(for categoryRaw: String?) -> String {
        guard let raw = categoryRaw else { return "Other" }
        switch raw {
        case "produce": return "Produce"
        case "protein": return "Protein"
        case "dairy": return "Dairy"
        case "grain": return "Grains"
        case "pantry": return "Pantry"
        case "spice": return "Spices"
        case "condiment": return "Condiments"
        default: return "Other"
        }
    }
}
