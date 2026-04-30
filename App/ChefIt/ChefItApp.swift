import SwiftUI
import UIKit
import ChefItKit

@main
struct ChefItApp: App {
    @StateObject private var ingredientBoard = IngredientStore(persister: UserDefaultsIngredientPersister())
    @StateObject private var shoppingCart = ShoppingCartViewModel()

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
            }
            .preferredColorScheme(.light)
        }
    }
}
