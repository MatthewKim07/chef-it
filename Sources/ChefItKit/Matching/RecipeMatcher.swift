import Foundation

/// Optional context the matcher uses to score and explain matches. The
/// planner produces this from the ingredient board so ranking reflects
/// Pantry Pal's protein-led intent (a recipe centered on the user's pantry
/// protein outranks one that just happens to share a few staples).
public struct RecipeMatchingContext: Sendable, Hashable {
    public let plannerProteins: [String]      // canonicalized
    public let plannerSupporting: [String]    // canonicalized

    public init(plannerProteins: [String] = [], plannerSupporting: [String] = []) {
        self.plannerProteins = plannerProteins
        self.plannerSupporting = plannerSupporting
    }

    public static let empty = RecipeMatchingContext()
}

/// Recipe matching engine.
///
/// Behavior:
/// - Inputs canonicalized via `IngredientNormalizer`.
/// - Match check: `recipeIng.contains(userIng) || userIng.contains(recipeIng)`.
/// - `ready`  = zero missing required ingredients.
/// - `almost` = 1...almostThreshold missing required ingredients.
/// - Score = coverage + protein boost − missing penalty − tiny time tiebreaker.
/// - Sort: score desc, cookingMinutes asc, recipe.id asc → fully deterministic.
public struct RecipeMatcher: Sendable {
    public struct ScoringWeights: Sendable {
        public let coverage: Double
        public let proteinHit: Double
        public let missingPenalty: Double
        public let timeTiebreaker: Double

        public init(
            coverage: Double = 1.0,
            proteinHit: Double = 0.20,
            missingPenalty: Double = 0.05,
            timeTiebreaker: Double = 0.001
        ) {
            self.coverage = coverage
            self.proteinHit = proteinHit
            self.missingPenalty = missingPenalty
            self.timeTiebreaker = timeTiebreaker
        }

        public static let standard = ScoringWeights()
    }

    public let normalizer: IngredientNormalizer
    public let almostThreshold: Int
    public let weights: ScoringWeights

    public init(
        normalizer: IngredientNormalizer = IngredientNormalizer(),
        almostThreshold: Int = 2,
        weights: ScoringWeights = .standard
    ) {
        self.normalizer = normalizer
        self.almostThreshold = almostThreshold
        self.weights = weights
    }

    public func evaluate(
        recipe: Recipe,
        against userCanonicals: [String],
        context: RecipeMatchingContext = .empty
    ) -> RecipeMatch {
        var matched: [String] = []
        var missing: [String] = []
        var recipeCanonicals: Set<String> = []

        for recipeIng in recipe.ingredients {
            let canonRecipe = normalizer.canonicalize(recipeIng)
            recipeCanonicals.insert(canonRecipe)
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

        // Score components
        let plannerProteinSet = Set(context.plannerProteins)
        let proteinIntersection = recipeCanonicals.intersection(plannerProteinSet)
        let hasProteinHit = !proteinIntersection.isEmpty
        let proteinBoost = hasProteinHit ? weights.proteinHit : 0.0

        let score = (coverage * weights.coverage)
            + proteinBoost
            - (Double(missing.count) * weights.missingPenalty)
            - (Double(recipe.cookingMinutes) * weights.timeTiebreaker)

        let rationale = buildRationale(
            recipe: recipe,
            matchedCount: matched.count,
            missing: missing,
            status: status,
            proteinIntersection: proteinIntersection
        )

        return RecipeMatch(
            recipe: recipe,
            matchedIngredients: matched,
            missingIngredients: missing,
            coverage: coverage,
            status: status,
            score: score,
            rationale: rationale
        )
    }

    public func match(
        ingredients: [Ingredient],
        recipes: [Recipe],
        context: RecipeMatchingContext = .empty
    ) -> MatchResults {
        let canonicals = ingredients.map(\.canonicalName)
        var ready: [RecipeMatch] = []
        var almost: [RecipeMatch] = []

        for recipe in recipes {
            let match = evaluate(recipe: recipe, against: canonicals, context: context)
            switch match.status {
            case .ready: ready.append(match)
            case .almost: almost.append(match)
            case .excluded: continue
            }
        }

        ready = stableSort(ready)
        almost = stableSort(almost)

        return MatchResults(ready: ready, almost: almost)
    }

    /// Multi-key stable ordering. Lexicographic on (−score, cookingMinutes, id)
    /// so ties unwind deterministically.
    private func stableSort(_ matches: [RecipeMatch]) -> [RecipeMatch] {
        matches.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            if lhs.recipe.cookingMinutes != rhs.recipe.cookingMinutes {
                return lhs.recipe.cookingMinutes < rhs.recipe.cookingMinutes
            }
            return lhs.recipe.id < rhs.recipe.id
        }
    }

    private func buildRationale(
        recipe: Recipe,
        matchedCount: Int,
        missing: [String],
        status: MatchStatus,
        proteinIntersection: Set<String>
    ) -> [String] {
        var lines: [String] = []
        let total = recipe.ingredients.count

        switch status {
        case .ready:
            lines.append("All \(total) ingredients on board.")
        case .almost:
            let count = missing.count
            let preview = missing.prefix(3).joined(separator: ", ")
            if count == 1 {
                lines.append("Need 1 more: \(preview).")
            } else {
                lines.append("Need \(count) more: \(preview).")
            }
        case .excluded:
            lines.append("Too many gaps to surface (\(missing.count) missing).")
        }

        if let protein = proteinIntersection.sorted().first {
            lines.append("Built around your \(protein).")
        }

        if recipe.cookingMinutes <= 15 {
            lines.append("Quick — \(recipe.cookingMinutes) min.")
        }

        return lines
    }
}
