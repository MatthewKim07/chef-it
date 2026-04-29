import Foundation

public enum LiveRecipeSearchServiceFactory {
    public static func makeDefault() -> any RecipeSearchService {
        guard let configuration = RecipeAPIConfiguration.fromEnvironment() else {
            return MissingRecipeAPIConfigurationService()
        }

        return EdamamRecipeSearchService(configuration: configuration)
    }
}

public struct MissingRecipeAPIConfigurationService: RecipeSearchService {
    public init() {}

    public func search(query: RecipeQuery) async throws -> [Recipe] {
        throw RecipeSearchError.missingCredentials
    }
}
