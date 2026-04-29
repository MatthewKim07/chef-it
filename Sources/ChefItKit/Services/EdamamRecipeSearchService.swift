import Foundation

public protocol RecipeAPITransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: RecipeAPITransport {}

public struct EdamamRecipeSearchService: RecipeSearchService {
    private let configuration: RecipeAPIConfiguration
    private let transport: any RecipeAPITransport
    private let adapter: EdamamRecipeAdapter
    private let deduplicator: RecipeDeduplicator
    private let decoder: JSONDecoder
    private let baseURL: URL
    private let maxResultsPerRequest: Int
    private let supportingIngredientLimit: Int

    public init(
        configuration: RecipeAPIConfiguration,
        transport: any RecipeAPITransport = URLSession.shared,
        adapter: EdamamRecipeAdapter = EdamamRecipeAdapter(),
        deduplicator: RecipeDeduplicator = RecipeDeduplicator(),
        decoder: JSONDecoder = JSONDecoder(),
        baseURL: URL = URL(string: "https://api.edamam.com/api/recipes/v2")!,
        maxResultsPerRequest: Int = 12,
        supportingIngredientLimit: Int = 3
    ) {
        self.configuration = configuration
        self.transport = transport
        self.adapter = adapter
        self.deduplicator = deduplicator
        self.decoder = decoder
        self.baseURL = baseURL
        self.maxResultsPerRequest = maxResultsPerRequest
        self.supportingIngredientLimit = supportingIngredientLimit
    }

    public func search(query: RecipeQuery) async throws -> [Recipe] {
        let terms = searchTerms(for: query)
        var recipes: [Recipe] = []
        var firstFailure: Error?

        await withTaskGroup(of: Result<[Recipe], Error>.self) { group in
            for term in terms {
                group.addTask {
                    do {
                        return .success(try await fetchRecipes(for: term, query: query))
                    } catch {
                        return .failure(error)
                    }
                }
            }

            for await result in group {
                switch result {
                case .success(let resultRecipes):
                    recipes.append(contentsOf: resultRecipes)
                case .failure(let error):
                    firstFailure = firstFailure ?? error
                }
            }
        }

        if recipes.isEmpty {
            if let firstFailure {
                throw firstFailure
            }
            throw RecipeSearchError.noSuccessfulResponses
        }

        return deduplicator.deduplicate(recipes)
    }

    func searchTerms(for query: RecipeQuery) -> [String] {
        let supporting = query.canonicalIngredients
            .filter { !query.proteins.contains($0) }
            .prefix(supportingIngredientLimit)

        guard !query.proteins.isEmpty else {
            let allIngredients = query.canonicalIngredients.prefix(supportingIngredientLimit + 2)
            let term = allIngredients.joined(separator: " ")
            return [term.isEmpty ? "recipe" : term]
        }

        return query.proteins.map { protein in
            ([protein] + supporting).joined(separator: " ")
        }
    }

    func makeRequest(term: String, query: RecipeQuery) throws -> URLRequest {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems(term: term, query: query)

        guard let url = components?.url else {
            throw RecipeSearchError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        return request
    }

    private func fetchRecipes(for term: String, query: RecipeQuery) async throws -> [Recipe] {
        let request = try makeRequest(term: term, query: query)
        let (data, response) = try await transport.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RecipeSearchError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw RecipeSearchError.httpStatus(httpResponse.statusCode)
        }

        do {
            let recipes = try adapter.adapt(decoder.decode(EdamamSearchResponse.self, from: data))
            return Array(recipes.prefix(maxResultsPerRequest))
        } catch {
            throw RecipeSearchError.decodingFailed
        }
    }

    private func queryItems(term: String, query: RecipeQuery) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "type", value: "public"),
            URLQueryItem(name: "app_id", value: configuration.appID),
            URLQueryItem(name: "app_key", value: configuration.appKey),
            URLQueryItem(name: "q", value: term),
            URLQueryItem(name: "imageSize", value: "REGULAR")
        ]

        for tag in query.dietaryTags {
            items.append(URLQueryItem(name: "health", value: mapDietaryTag(tag)))
        }

        if let maxCookingMinutes = query.maxCookingMinutes {
            items.append(URLQueryItem(name: "time", value: "\(maxCookingMinutes)"))
        }

        items.append(contentsOf: [
            "uri",
            "label",
            "image",
            "images",
            "url",
            "yield",
            "dietLabels",
            "healthLabels",
            "ingredientLines",
            "ingredients",
            "calories",
            "totalTime",
            "cuisineType"
        ].map { URLQueryItem(name: "field", value: $0) })

        return items
    }

    private func mapDietaryTag(_ tag: String) -> String {
        switch tag.lowercased() {
        case "keto":
            return "keto-friendly"
        case "nut-free":
            return "tree-nut-free"
        default:
            return tag.lowercased()
        }
    }
}
