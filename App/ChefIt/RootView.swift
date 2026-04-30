import SwiftUI
import ChefItKit

struct RootView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var userProfileStore: CurrentUserProfileStore

    var body: some View {
        Group {
            if authService.isLoggedIn {
                ChefitRootCoordinatorView()
            } else {
                ChefitGuestFlowView()
            }
        }
        .task(id: authService.currentUser?.id) {
            if let id = authService.currentUser?.id {
                await userProfileStore.load(userId: id)
            } else {
                userProfileStore.clear()
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
        .environmentObject(CurrentUserProfileStore())
}
