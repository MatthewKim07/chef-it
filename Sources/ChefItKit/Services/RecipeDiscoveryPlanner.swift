import Foundation

/// Pantry Pal does not query recipes with one flat ingredient list.
/// It first separates proteins from everything else, then uses that split to
/// shape search requests and later re-rank matches client-side.
public struct RecipeDiscoveryPlanner: Sendable {
    private let detector: ProteinDetector

    public init(detector: ProteinDetector = ProteinDetector()) {
        self.detector = detector
    }

    public func makePlan(
        from ingredients: [Ingredient],
        dietaryTags: [String] = [],
        maxCookingMinutes: Int? = nil
    ) -> RecipeDiscoveryPlan {
        let canonicalIngredients = ingredients.map(\.canonicalName)
        let split = detector.split(canonicalIngredients)

        return RecipeDiscoveryPlan(
            query: RecipeQuery(
                canonicalIngredients: canonicalIngredients,
                proteins: split.proteins,
                dietaryTags: dietaryTags,
                maxCookingMinutes: maxCookingMinutes
            ),
            canonicalIngredients: canonicalIngredients,
            proteins: split.proteins,
            supportingIngredients: split.others
        )
    }
}

public struct RecipeDiscoveryPlan: Sendable {
    public let query: RecipeQuery
    public let canonicalIngredients: [String]
    public let proteins: [String]
    public let supportingIngredients: [String]

    public init(
        query: RecipeQuery,
        canonicalIngredients: [String],
        proteins: [String],
        supportingIngredients: [String]
    ) {
        self.query = query
        self.canonicalIngredients = canonicalIngredients
        self.proteins = proteins
        self.supportingIngredients = supportingIngredients
    }

    /// Context the matcher uses to score and explain candidates.
    public var matchingContext: RecipeMatchingContext {
        RecipeMatchingContext(
            plannerProteins: proteins,
            plannerSupporting: supportingIngredients
        )
    }
}
