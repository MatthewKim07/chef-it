import Foundation
import Testing
@testable import ChefItKit

@Suite("EdamamRecipeSearchService")
struct EdamamRecipeSearchServiceTests {
    private actor RequestRecorder {
        private(set) var requests: [URLRequest] = []

        func record(_ request: URLRequest) {
            requests.append(request)
        }

        func allRequests() -> [URLRequest] {
            requests
        }
    }

    private struct RecordingTransport: RecipeAPITransport {
        let recorder: RequestRecorder
        let data: Data
        let statusCode: Int

        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            await recorder.record(request)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        }
    }

    private var configuration: RecipeAPIConfiguration {
        RecipeAPIConfiguration(appID: "test-id", appKey: "test-key")
    }

    @Test func buildsProteinFanoutTermsFromQuery() {
        let service = EdamamRecipeSearchService(configuration: configuration)
        let query = RecipeQuery(
            canonicalIngredients: ["chicken", "lemon", "garlic", "rice", "salt"],
            proteins: ["chicken"]
        )

        #expect(service.searchTerms(for: query) == ["chicken lemon garlic rice"])
    }

    @Test func buildsBroadSearchTermWithoutProtein() {
        let service = EdamamRecipeSearchService(configuration: configuration)
        let query = RecipeQuery(canonicalIngredients: ["tomato", "garlic"])

        #expect(service.searchTerms(for: query) == ["tomato garlic"])
    }

    @Test func requestIncludesCredentialsAndFilters() throws {
        let service = EdamamRecipeSearchService(
            configuration: configuration,
            baseURL: URL(string: "https://api.example.test/recipes")!
        )
        let request = try service.makeRequest(
            term: "chicken lemon",
            query: RecipeQuery(
                canonicalIngredients: ["chicken", "lemon"],
                proteins: ["chicken"],
                dietaryTags: ["gluten-free", "keto"],
                maxCookingMinutes: 30
            )
        )

        let components = try #require(URLComponents(url: request.url!, resolvingAgainstBaseURL: false))
        let queryItems = components.queryItems ?? []

        #expect(queryItems.contains(URLQueryItem(name: "type", value: "public")))
        #expect(queryItems.contains(URLQueryItem(name: "app_id", value: "test-id")))
        #expect(queryItems.contains(URLQueryItem(name: "app_key", value: "test-key")))
        #expect(queryItems.contains(URLQueryItem(name: "q", value: "chicken lemon")))
        #expect(queryItems.contains(URLQueryItem(name: "health", value: "gluten-free")))
        #expect(queryItems.contains(URLQueryItem(name: "health", value: "keto-friendly")))
        #expect(queryItems.contains(URLQueryItem(name: "time", value: "30")))
        #expect(queryItems.contains(URLQueryItem(name: "field", value: "ingredientLines")))
    }

    @Test func searchAdaptsAndDeduplicatesAPIResponses() async throws {
        let json = """
        {
          "hits": [
            {
              "recipe": {
                "uri": "http://www.edamam.com/ontologies/edamam.owl#recipe_first",
                "label": "First Chicken",
                "url": "https://example.com/chicken",
                "ingredientLines": ["chicken", "lemon"],
                "totalTime": 20
              }
            },
            {
              "recipe": {
                "uri": "http://www.edamam.com/ontologies/edamam.owl#recipe_duplicate",
                "label": "Duplicate Chicken",
                "url": "https://example.com/chicken",
                "ingredientLines": ["chicken", "garlic"],
                "totalTime": 25
              }
            }
          ]
        }
        """.data(using: .utf8)!
        let recorder = RequestRecorder()
        let service = EdamamRecipeSearchService(
            configuration: configuration,
            transport: RecordingTransport(recorder: recorder, data: json, statusCode: 200)
        )

        let recipes = try await service.search(
            query: RecipeQuery(
                canonicalIngredients: ["chicken", "lemon", "garlic"],
                proteins: ["chicken"]
            )
        )

        #expect(recipes.map(\.id) == ["first"])
        #expect(await recorder.allRequests().count == 1)
    }

    @Test func throwsHTTPStatusForFailedAPIResponse() async {
        let recorder = RequestRecorder()
        let service = EdamamRecipeSearchService(
            configuration: configuration,
            transport: RecordingTransport(recorder: recorder, data: Data(), statusCode: 401)
        )

        await #expect(throws: RecipeSearchError.httpStatus(401)) {
            try await service.search(query: RecipeQuery(canonicalIngredients: ["chicken"]))
        }
    }

    @Test func factoryReturnsMissingConfigurationServiceWithoutCredentials() async {
        let service = MissingRecipeAPIConfigurationService()

        await #expect(throws: RecipeSearchError.missingCredentials) {
            try await service.search(query: RecipeQuery(canonicalIngredients: ["tomato"]))
        }
    }
}
