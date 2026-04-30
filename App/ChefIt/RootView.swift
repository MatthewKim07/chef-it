import SwiftUI
import ChefItKit

struct RootView: View {
    @StateObject private var authService = AuthService.shared

    var body: some View {
        if authService.isLoggedIn {
            ChefitRootCoordinatorView()
        } else {
            LoginView()
                .environmentObject(authService)
        }
    }
}

#Preview {
    RootView()
}
