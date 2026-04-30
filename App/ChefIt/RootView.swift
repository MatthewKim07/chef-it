import SwiftUI
import ChefItKit

struct RootView: View {
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        Group {
            if authService.isLoggedIn {
                ChefitRootCoordinatorView()
            } else {
                ChefitGuestFlowView()
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthService.shared)
        .environmentObject(IngredientStore())
        .environmentObject(ShoppingCartViewModel())
        .environmentObject(HomeFeedViewModel())
}
