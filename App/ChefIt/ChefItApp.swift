import SwiftUI
import UIKit
import ChefItKit

@MainActor
final class CurrentUserProfileStore: ObservableObject {
    @Published var profile: UserProfile?

    func load(userId: Int, force: Bool = false) async {
        if !force, let p = profile, p.id == userId { return }
        do {
            profile = try await UserService.shared.fetchProfile(id: userId)
        } catch {
            // Falls back to defaults in the UI; not a fatal error.
        }
    }

    func update(_ profile: UserProfile?) {
        self.profile = profile
    }

    func clear() {
        profile = nil
    }
}

@main
struct ChefItApp: App {
    @StateObject private var ingredientBoard = IngredientStore(persister: UserDefaultsIngredientPersister())
    @StateObject private var shoppingCart = ShoppingCartViewModel()
    @StateObject private var homeFeed = HomeFeedViewModel()
    @StateObject private var userProfileStore = CurrentUserProfileStore()

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
                    .environmentObject(ingredientBoard)
                    .environmentObject(shoppingCart)
                    .environmentObject(homeFeed)
                    .environmentObject(userProfileStore)
            }
            .preferredColorScheme(.light)
        }
    }
}
