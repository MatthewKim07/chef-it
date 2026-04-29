import Foundation
import Testing
@testable import ChefItKit

@Suite("EdamamRecipeAdapter")
struct EdamamRecipeAdapterTests {
    @Test func adaptsCoreRecipeFields() throws {
        let json = """
        {
          "hits": [
            {
              "recipe": {
                "uri": "http://www.edamam.com/ontologies/edamam.owl#recipe_abc123",
                "label": "Lemon Chicken",
                "image": "https://example.com/fallback.jpg",
                "images": {
                  "REGULAR": { "url": "https://example.com/regular.jpg" }
                },
                "url": "https://example.com/source",
                "yield": 4,
                "dietLabels": ["High-Protein"],
                "healthLabels": ["Gluten-Free", "Dairy-Free"],
                "ingredientLines": ["chicken", "lemon", "garlic"],
                "ingredients": [
                  { "text": "1 lb chicken breast", "food": "chicken" },
                  { "text": "1 lemon", "food": "lemon" },
                  { "text": "2 garlic cloves", "food": "garlic" },
                  { "text": "extra garlic", "food": "garlic" }
                ],
                "calories": 1200,
                "totalTime": 45,
                "cuisineType": ["mediterranean"]
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(EdamamSearchResponse.self, from: json)
        let recipe = try #require(EdamamRecipeAdapter().adapt(response).first)

        #expect(recipe.id == "abc123")
        #expect(recipe.title == "Lemon Chicken")
        #expect(recipe.cookingMinutes == 45)
        #expect(recipe.difficulty == .medium)
        #expect(recipe.servings == 4)
        #expect(recipe.cuisine == "Mediterranean")
        #expect(recipe.ingredients == ["chicken", "lemon", "garlic"])
        #expect(recipe.dietaryTags == ["gluten-free", "dairy-free"])
        #expect(recipe.imageURL?.absoluteString == "https://example.com/regular.jpg")
        #expect(recipe.sourceURL?.absoluteString == "https://example.com/source")
        #expect(recipe.blurb.contains("300 calories per serving"))
    }

    @Test func fallsBackWhenOptionalFieldsAreMissing() throws {
        let json = """
        {
          "hits": [
            {
              "recipe": {
                "uri": "recipe_without_hash",
                "label": "Simple Rice",
                "url": "https://example.com/rice",
                "ingredients": [
                  { "text": "white rice" },
                  { "food": "salt" }
                ]
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(EdamamSearchResponse.self, from: json)
        let recipe = try #require(EdamamRecipeAdapter().adapt(response).first)

        #expect(recipe.id == "recipe_without_hash")
        #expect(recipe.cookingMinutes == 30)
        #expect(recipe.difficulty == .easy)
        #expect(recipe.servings == 2)
        #expect(recipe.cuisine == "International")
        #expect(recipe.ingredients == ["white rice", "salt"])
    }
}
