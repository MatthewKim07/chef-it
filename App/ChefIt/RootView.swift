import SwiftUI
import ChefItKit

struct RootView: View {
    @StateObject private var authService = AuthService.shared

    var body: some View {
        if authService.isLoggedIn {
            ChefItMilestoneOneView()
        } else {
            LoginView()
                .environmentObject(authService)
        }
    }
}

#Preview {
    RootView()
}
