import SwiftUI
import ChefItKit

enum ChefitRoute: Hashable {
    case home
    case search
    case recipeDiscover(id: String)
    case recipeDetails(id: String)
    case scan
    case detectedIngredients
    case recommendations
    case shoppingList
    case saved
    case profile
    case community
}

struct ChefitRootCoordinatorView: View {
    // RootView already owns unauthenticated entry. The coordinator should start
    // inside the authenticated app shell rather than replaying placeholder auth.
    @State private var route: ChefitRoute = .home
    @State private var selectedTab: ChefitTab = .home

    var body: some View {
        routeView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ChefitColors.cream.ignoresSafeArea(edges: .all))
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if showsBottomNav {
                    ChefitBottomNavBar(activeTab: selectedTab) { tab in
                        selectedTab = tab
                        switch tab {
                        case .home:
                            route = .home
                        case .search:
                            route = .search
                        case .scan:
                            route = .scan
                        case .saved:
                            route = .saved
                        case .community:
                            route = .community
                        }
                    }
                }
            }
        .onChange(of: route) { _, newValue in
            switch newValue {
            case .home: selectedTab = .home
            case .search: selectedTab = .search
            case .scan, .detectedIngredients, .recommendations: selectedTab = .scan
            case .saved: selectedTab = .saved
            case .community: selectedTab = .community
            default: break
            }
        }
    }

    private var showsBottomNav: Bool {
        true
    }

    @ViewBuilder
    private var routeView: some View {
        switch route {
        case .home:
            ChefitHomeView(
                onSearchTap: { route = .search },
                onRecipeTap: { recipeID in route = .recipeDiscover(id: recipeID) }
            )
        case .search:
            ChefitSearchView { recipeID in
                route = .recipeDiscover(id: recipeID)
            }
        case .recipeDiscover(let id):
            let recipe = ChefitSampleData.popularRecipes.first(where: { $0.id == id }) ?? ChefitSampleData.popularRecipes[0]
            ChefitRecipeDiscoveryView(recipe: recipe) {
                route = .recipeDetails(id: id)
            }
        case .recipeDetails:
            ChefitRecipeDetailsView {
                route = .recipeDetails(id: "cooking-mode")
            }
        case .scan:
            ChefitScanPantryView(
                onScanNow: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        route = .detectedIngredients
                    }
                },
                onAddManually: { route = .home }
            )
        case .detectedIngredients:
            ChefitDetectedIngredientsView {
                route = .recommendations
            }
        case .recommendations:
            ChefitRecommendationsView { recipeID in
                route = .recipeDiscover(id: recipeID)
            }
        case .shoppingList:
            ChefitShoppingListView()
        case .saved:
            ChefitSavedView { recipeID in
                route = .recipeDiscover(id: recipeID)
            }
        case .profile:
            ChefitProfileView(
                onShoppingTap: { route = .shoppingList },
                onPantryTap: { route = .scan },
                onLogout: { AuthService.shared.logout() }
            )
        case .community:
            ChefitCommunityView()
        }
    }

    private func routePlaceholder(_ title: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: ChefitSpacing.lg) {
            Text(title)
                .font(ChefitTypography.h1())
                .foregroundStyle(ChefitColors.sageGreen)
            Button("Continue") {
                action()
            }
            .buttonStyle(ChefitPrimaryButtonStyle())
        }
        .padding(ChefitSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChefitColors.cream.ignoresSafeArea())
    }
}
