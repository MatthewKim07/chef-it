import Foundation

public struct TheMealDBRecipeSearchService: RecipeSearchService {
    private let session: URLSession
    private static let base = "https://www.themealdb.com/api/json/v1/1"
    private static let maxResults = 20

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func search(query: RecipeQuery) async throws -> [Recipe] {
        let searchTerms = query.proteins.isEmpty ? query.canonicalIngredients : query.proteins

        let mealIDs: [String]
        if searchTerms.isEmpty {
            mealIDs = try await fetchPopularMealIDs()
        } else {
            mealIDs = try await fetchMealIDs(for: Array(searchTerms.prefix(2)))
        }

        guard !mealIDs.isEmpty else { return [] }
        let meals = try await fetchMealDetails(ids: Array(mealIDs.prefix(Self.maxResults)))
        return meals.map(adapt)
    }

    private func fetchPopularMealIDs() async throws -> [String] {
        let categories = ["Chicken", "Beef", "Pasta", "Seafood", "Vegetarian"]
        var seen = Set<String>()
        var ids: [String] = []
        for category in categories {
            let url = URL(string: "\(Self.base)/filter.php?c=\(category)")!
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(TheMealDBFilterResponse.self, from: data)
            for meal in (response.meals ?? []).prefix(4) {
                if seen.insert(meal.idMeal).inserted {
                    ids.append(meal.idMeal)
                }
            }
        }
        return ids
    }

    private func fetchMealIDs(for terms: [String]) async throws -> [String] {
        var seen = Set<String>()
        var ids: [String] = []
        for term in terms {
            let url = URL(string: "\(Self.base)/filter.php?i=\(term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? term)")!
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(TheMealDBFilterResponse.self, from: data)
            for meal in response.meals ?? [] {
                if seen.insert(meal.idMeal).inserted {
                    ids.append(meal.idMeal)
                }
            }
        }
        return ids
    }

    private func fetchMealDetails(ids: [String]) async throws -> [TheMealDBMeal] {
        try await withThrowingTaskGroup(of: TheMealDBMeal?.self) { group in
            for id in ids {
                group.addTask {
                    let url = URL(string: "\(Self.base)/lookup.php?i=\(id)")!
                    let (data, _) = try await self.session.data(from: url)
                    let response = try JSONDecoder().decode(TheMealDBLookupResponse.self, from: data)
                    return response.meals?.first
                }
            }
            var results: [TheMealDBMeal] = []
            for try await meal in group {
                if let meal { results.append(meal) }
            }
            return results
        }
    }

    private func adapt(_ meal: TheMealDBMeal) -> Recipe {
        let cookingMinutes = estimateCookingMinutes(instructions: meal.strInstructions)
        let difficulty = estimateDifficulty(ingredientCount: meal.ingredients.count)
        let dietaryTags = dietaryTags(for: meal.strCategory)
        return Recipe(
            id: "mealdb-\(meal.idMeal)",
            title: meal.strMeal,
            blurb: meal.strArea.map { "\($0) cuisine" } ?? "",
            cookingMinutes: cookingMinutes,
            servings: 4,
            cuisine: meal.strArea ?? "",
            difficulty: difficulty,
            ingredients: meal.ingredients,
            dietaryTags: dietaryTags,
            imageURL: meal.strMealThumb.flatMap(URL.init),
            sourceURL: meal.strSource.flatMap(URL.init),
            mealCategory: meal.strCategory ?? ""
        )
    }

    private func estimateCookingMinutes(instructions: String?) -> Int {
        guard let instructions else { return 30 }
        let wordCount = instructions.split(separator: " ").count
        switch wordCount {
        case ..<100: return 15
        case 100..<300: return 30
        case 300..<600: return 45
        default: return 60
        }
    }

    private func estimateDifficulty(ingredientCount: Int) -> Difficulty {
        switch ingredientCount {
        case ..<6: return .easy
        case 6..<12: return .medium
        default: return .hard
        }
    }

    private func dietaryTags(for category: String?) -> [String] {
        switch category?.lowercased() {
        case "vegetarian": return ["vegetarian"]
        case "vegan": return ["vegan", "vegetarian"]
        case "dessert": return ["vegetarian"]
        default: return []
        }
    }
}
