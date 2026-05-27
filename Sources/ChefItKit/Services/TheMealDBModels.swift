import Foundation

struct TheMealDBFilterResponse: Decodable {
    let meals: [TheMealDBFilterMeal]?
}

struct TheMealDBFilterMeal: Decodable {
    let idMeal: String
}

struct TheMealDBLookupResponse: Decodable {
    let meals: [TheMealDBMeal]?
}

struct TheMealDBMeal: Decodable {
    let idMeal: String
    let strMeal: String
    let strCategory: String?
    let strArea: String?
    let strInstructions: String?
    let strMealThumb: String?
    let strSource: String?
    let strIngredient1: String?
    let strIngredient2: String?
    let strIngredient3: String?
    let strIngredient4: String?
    let strIngredient5: String?
    let strIngredient6: String?
    let strIngredient7: String?
    let strIngredient8: String?
    let strIngredient9: String?
    let strIngredient10: String?
    let strIngredient11: String?
    let strIngredient12: String?
    let strIngredient13: String?
    let strIngredient14: String?
    let strIngredient15: String?
    let strIngredient16: String?
    let strIngredient17: String?
    let strIngredient18: String?
    let strIngredient19: String?
    let strIngredient20: String?

    var ingredients: [String] {
        [
            strIngredient1, strIngredient2, strIngredient3,
            strIngredient4, strIngredient5, strIngredient6,
            strIngredient7, strIngredient8, strIngredient9,
            strIngredient10, strIngredient11, strIngredient12,
            strIngredient13, strIngredient14, strIngredient15,
            strIngredient16, strIngredient17, strIngredient18,
            strIngredient19, strIngredient20
        ]
        .compactMap { $0 }
        .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        .map { $0.lowercased() }
    }
}
