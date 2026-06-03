import SwiftUI
import UIKit
import UserNotifications
import GoogleSignIn
import ChefItKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { await NotificationService.shared.registerDeviceToken(token) }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("APNs registration failed: \(error.localizedDescription)")
    }
}

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

@MainActor
final class SavedRecipeStore: ObservableObject {
    @Published private(set) var recipes: [ChefitRecipeItem] = []
    private let key = "ChefIt.SavedRecipes.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([ChefitRecipeItem].self, from: data) {
            recipes = saved
        }
    }

    func isSaved(_ id: String) -> Bool {
        recipes.contains { $0.id == id }
    }

    func toggle(_ recipe: ChefitRecipeItem) {
        if let idx = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes.remove(at: idx)
        } else {
            recipes.insert(recipe, at: 0)
        }
        persist()
    }

    func remove(at offsets: IndexSet) {
        recipes.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(recipes) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

@main
struct ChefItApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var ingredientBoard = IngredientStore.live()
    @StateObject private var shoppingCart = ShoppingCartViewModel()
    @StateObject private var homeFeed = HomeFeedViewModel()
    @StateObject private var userProfileStore = CurrentUserProfileStore()
    @StateObject private var savedRecipes = SavedRecipeStore()

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
                    .environmentObject(savedRecipes)
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
            .preferredColorScheme(.light)
        }
    }
}
