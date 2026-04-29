import Foundation

/// Recipe matching engine. Reproduces Pantry Pal's bidirectional
/// substring fuzzy match plus the Ready-to-Cook / Almost-There split,
/// with an explicit `almostThreshold` Pantry Pal lacks (it caps nothing).
///
/// Behavior in milestone 1:
/// - Inputs canonicalized via `IngredientNormalizer`.
/// - Match check: `recipeIng.contains(userIng) || userIng.contains(recipeIng)`.
/// - `ready` = zero missing required ingredients.
/// - `almost` = 1...almostThreshold missing required ingredients.
/// - Sort: ready by cookingMinutes asc; almost by missing.count asc, ties by cookingMinutes.
public struct RecipeMatcher: Sendable {
    public let normalizer: IngredientNormalizer
    public let almostThreshold: Int

    public init(
        normalizer: IngredientNormalizer = IngredientNormalizer(),
        almostThreshold: Int = 2
    ) {
        self.normalizer = normalizer
        self.almostThreshold = almostThreshold
    }

    public func evaluate(recipe: Recipe, against userCanonicals: [String]) -> RecipeMatch {
        var matched: [String] = []
        var missing: [String] = []

        for recipeIng in recipe.ingredients {
            let canonRecipe = normalizer.canonicalize(recipeIng)
            let hit = userCanonicals.contains { user in
                canonRecipe.contains(user) || user.contains(canonRecipe)
            }
            if hit { matched.append(recipeIng) } else { missing.append(recipeIng) }
        }

        let coverage = recipe.ingredients.isEmpty
            ? 0.0
            : Double(matched.count) / Double(recipe.ingredients.count)

        let status: MatchStatus
        if missing.isEmpty {
            status = .ready
        } else if missing.count <= almostThreshold {
            status = .almost
        } else {
            status = .excluded
        }

        return RecipeMatch(
            recipe: recipe,
            matchedIngredients: matched,
            missingIngredients: missing,
            coverage: coverage,
            status: status
        )
    }

    public func match(ingredients: [Ingredient], recipes: [Recipe]) -> MatchResults {
        let canonicals = ingredients.map(\.canonicalName)
        var ready: [RecipeMatch] = []
        var almost: [RecipeMatch] = []

        for recipe in recipes {
            let match = evaluate(recipe: recipe, against: canonicals)
            switch match.status {
            case .ready: ready.append(match)
            case .almost: almost.append(match)
            case .excluded: continue
            }
        }

        ready.sort { $0.recipe.cookingMinutes < $1.recipe.cookingMinutes }
        almost.sort { lhs, rhs in
            if lhs.missingIngredients.count != rhs.missingIngredients.count {
                return lhs.missingIngredients.count < rhs.missingIngredients.count
            }
            return lhs.recipe.cookingMinutes < rhs.recipe.cookingMinutes
        }

        return MatchResults(ready: ready, almost: almost)
    }
}
