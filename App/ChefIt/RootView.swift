import SwiftUI
import ChefItKit

struct RootView: View {
    @StateObject private var model = ChefItMilestoneOneViewModel(
        ingredientStore: IngredientStore.live()
    )

    var body: some View {
        ChefItMilestoneOneView(model: model)
    }
}

#Preview {
    RootView()
}
