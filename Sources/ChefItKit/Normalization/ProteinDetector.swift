import Foundation

/// Whole-word protein keyword detection. Mirrors Pantry Pal's
/// `proteinDetection.ts` — intent is to influence recipe search ranking
/// (multi-protein fan-out) rather than gate matching.
public struct ProteinDetector: Sendable {
    public static let keywords: Set<String> = [
        // Poultry
        "chicken", "turkey", "duck", "goose", "quail",
        // Red meat
        "beef", "steak", "veal", "lamb", "mutton", "bison", "venison",
        // Pork
        "pork", "bacon", "ham", "sausage", "chorizo", "prosciutto", "pancetta",
        // Fish
        "fish", "salmon", "tuna", "cod", "halibut", "tilapia", "trout",
        "bass", "mackerel", "sardine", "anchovy", "snapper", "swordfish",
        "mahi", "catfish",
        // Shellfish
        "shrimp", "prawn", "crab", "lobster", "scallop", "clam", "mussel",
        "oyster", "calamari", "squid", "octopus", "crawfish", "crayfish",
        // Plant-based
        "tofu", "tempeh", "seitan",
        // Eggs
        "egg"
    ]

    public init() {}

    public func isProtein(_ ingredient: String) -> Bool {
        let lower = ingredient.lowercased()
        let tokens = lower.split(whereSeparator: { !$0.isLetter })
        for token in tokens {
            if Self.keywords.contains(String(token)) { return true }
        }
        return false
    }

    public func split(_ ingredients: [String]) -> (proteins: [String], others: [String]) {
        var proteins: [String] = []
        var others: [String] = []
        for ing in ingredients {
            if isProtein(ing) { proteins.append(ing) } else { others.append(ing) }
        }
        return (proteins, others)
    }
}
