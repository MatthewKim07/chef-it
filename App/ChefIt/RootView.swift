import SwiftUI
import ChefItKit

struct RootView: View {
    @StateObject private var model = ChefItMilestoneOneViewModel(
        ingredientStore: IngredientStore.live(),
        matcher: RecipeMatcher(almostThreshold: 8),
        recipeSearchService: LiveRecipeSearchServiceFactory.makeDefault()
    )

    var body: some View {
        ChefItMilestoneOneView(model: model)
    }
}

#Preview {
    RootView()
}
