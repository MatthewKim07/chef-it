import SwiftUI
import UIKit
import UserNotifications
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
                requestPushPermissions()
            } else {
                userProfileStore.clear()
            }
        }
    }
    private func requestPushPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
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
