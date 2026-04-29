import Foundation

/// Boundary for recipe sourcing. Mirrors the role Pantry Pal's
/// Edamam adapter plays — accepting a query and returning domain `Recipe`s,
/// agnostic of upstream API.
///
/// Real implementation (milestone 2+) will likely fan out per-protein like
/// Pantry Pal's `searchMultipleProteins` and dedupe by source URL.
public protocol RecipeSearchService: Sendable {
    func search(query: RecipeQuery) async throws -> [Recipe]
}

public struct RecipeQuery: Sendable, Hashable {
    public let canonicalIngredients: [String]
    public let proteins: [String]
    public let dietaryTags: [String]
    public let maxCookingMinutes: Int?

    public init(
        canonicalIngredients: [String],
        proteins: [String] = [],
        dietaryTags: [String] = [],
        maxCookingMinutes: Int? = nil
    ) {
        self.canonicalIngredients = canonicalIngredients
        self.proteins = proteins
        self.dietaryTags = dietaryTags
        self.maxCookingMinutes = maxCookingMinutes
    }
}

/// Local seed-driven implementation. Returns the full seed list and lets the
/// matcher do the work. Replaceable with an Edamam (or other) client later.
public struct LocalSeedRecipeSearchService: RecipeSearchService {
    private let seed: [Recipe]
    private let normalizer: IngredientNormalizer

    public init(
        seed: [Recipe] = SeedRecipes.all,
        normalizer: IngredientNormalizer = IngredientNormalizer()
    ) {
        self.seed = seed
        self.normalizer = normalizer
    }

    public func search(query: RecipeQuery) async throws -> [Recipe] {
        var candidates = seed

        if let maxCookingMinutes = query.maxCookingMinutes {
            candidates = candidates.filter { $0.cookingMinutes <= maxCookingMinutes }
        }

        if !query.dietaryTags.isEmpty {
            let requestedTags = Set(query.dietaryTags.map { $0.lowercased() })
            candidates = candidates.filter { recipe in
                let recipeTags = Set(recipe.dietaryTags.map { $0.lowercased() })
                return requestedTags.isSubset(of: recipeTags)
            }
        }

        guard !query.proteins.isEmpty else {
            return candidates
        }

        let requestedProteins = Set(query.proteins.map(normalizer.canonicalize))

        return candidates.sorted { lhs, rhs in
            let lhsScore = proteinScore(for: lhs, requestedProteins: requestedProteins)
            let rhsScore = proteinScore(for: rhs, requestedProteins: requestedProteins)

            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }

            return lhs.cookingMinutes < rhs.cookingMinutes
        }
    }

    private func proteinScore(for recipe: Recipe, requestedProteins: Set<String>) -> Int {
        let recipeCanonicals = Set(recipe.ingredients.map(normalizer.canonicalize))
        return recipeCanonicals.intersection(requestedProteins).count
    }
}
