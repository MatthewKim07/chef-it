import SwiftUI

enum ChefitRoute: Hashable {
    case splash
    case auth
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
    @State private var route: ChefitRoute = .splash
    @State private var selectedTab: ChefitTab = .home

    var body: some View {
        VStack(spacing: 0) {
            NavigationStack {
                routeView
                    .navigationBarBackButtonHidden(true)
            }

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
                    case .profile:
                        route = .profile
                    case .community:
                        route = .community
                    }
                }
            }
        }
        .background(ChefitColors.cream.ignoresSafeArea())
        .onChange(of: route) { _, newValue in
            switch newValue {
            case .home: selectedTab = .home
            case .search: selectedTab = .search
            case .scan, .detectedIngredients, .recommendations: selectedTab = .scan
            case .saved: selectedTab = .saved
            case .profile: selectedTab = .profile
            case .community: selectedTab = .community
            default: break
            }
        }
    }

    private var showsBottomNav: Bool {
        switch route {
        case .splash, .auth:
            return false
        default:
            return true
        }
    }

    @ViewBuilder
    private var routeView: some View {
        switch route {
        case .splash:
            routePlaceholder("Splash") { route = .auth }
        case .auth:
            routePlaceholder("Auth") { route = .home }
        case .home:
            routePlaceholder("Home") { route = .search }
        case .search:
            routePlaceholder("Search") { route = .recipeDiscover(id: "creamy-pasta") }
        case .recipeDiscover(let id):
            routePlaceholder("Discover \(id)") { route = .recipeDetails(id: id) }
        case .recipeDetails:
            routePlaceholder("Recipe details") {}
        case .scan:
            routePlaceholder("Scan") { route = .detectedIngredients }
        case .detectedIngredients:
            routePlaceholder("Detected ingredients") { route = .recommendations }
        case .recommendations:
            routePlaceholder("Recommendations") { route = .recipeDiscover(id: "creamy-pasta") }
        case .shoppingList:
            routePlaceholder("Shopping list") {}
        case .saved:
            routePlaceholder("Saved") { route = .recipeDiscover(id: "creamy-pasta") }
        case .profile:
            routePlaceholder("Profile") { route = .shoppingList }
        case .community:
            routePlaceholder("Community") {}
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
        .background(ChefitColors.cream)
    }
}
