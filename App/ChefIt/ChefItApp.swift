import SwiftUI
import UIKit
import ChefItKit

@main
struct ChefItApp: App {
    init() {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ChefitColors.cream
                    .ignoresSafeArea(edges: .all)
                RootView()
                    .environmentObject(AuthService.shared)
            }
            .preferredColorScheme(.light)
        }
    }
}
