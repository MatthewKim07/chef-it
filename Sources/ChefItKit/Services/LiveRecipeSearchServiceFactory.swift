import Foundation

public enum LiveRecipeSearchServiceFactory {
    public static func makeDefault() -> any RecipeSearchService {
        TheMealDBRecipeSearchService()
    }

    public static func makeEdamam() -> (any RecipeSearchService)? {
        guard let configuration = RecipeAPIConfiguration.fromEnvironment() else { return nil }
        return EdamamRecipeSearchService(configuration: configuration)
    }
}

public struct MissingRecipeAPIConfigurationService: RecipeSearchService {
    public init() {}

    public func search(query: RecipeQuery) async throws -> [Recipe] {
        throw RecipeSearchError.missingCredentials
    }
}
