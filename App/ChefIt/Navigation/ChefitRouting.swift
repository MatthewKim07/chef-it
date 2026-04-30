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
    case userProfile(id: Int)
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
                        case .community:
                            route = .community
                        case .profile:
                            route = .profile
                        }
                    }
                }
            }
        .onChange(of: route) { _, newValue in
            switch newValue {
            case .home: selectedTab = .home
            case .search: selectedTab = .search
            case .scan, .detectedIngredients, .recommendations: selectedTab = .scan
            case .community, .userProfile: selectedTab = .community
            case .profile: selectedTab = .profile
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
            ChefitCommunityView(
                onAuthorTap: { userId in route = .userProfile(id: userId) }
            )
        case .userProfile(let userId):
            OtherUserProfileView(userId: userId, onBack: { route = .community })
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

// MARK: - Other User Profile View

@MainActor
private final class OtherUserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var error: String?

    func load(userId: Int) async {
        isLoading = true
        error = nil
        async let profileTask = UserService.shared.fetchProfile(id: userId)
        async let postsTask   = PostService.shared.fetchPosts(userId: userId)
        do {
            let (p, pg) = try await (profileTask, postsTask)
            profile = p
            posts   = pg.posts
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct OtherUserProfileView: View {
    let userId: Int
    let onBack: () -> Void

    @StateObject private var vm = OtherUserProfileViewModel()

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: ChefitSpacing.lg) {
                    Color.clear.frame(height: 44)

                    // Avatar
                    Group {
                        if let urlStr = vm.profile?.avatarURL, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().scaledToFill()
                                } else { avatarPlaceholder }
                            }
                        } else { avatarPlaceholder }
                    }
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(ChefitColors.cream, lineWidth: 3))

                    if vm.isLoading {
                        ProgressView().tint(ChefitColors.sageGreen)
                    } else {
                        VStack(spacing: ChefitSpacing.sm) {
                            Text(vm.profile?.displayName ?? "Chef")
                                .font(ChefitTypography.h1())
                                .foregroundStyle(ChefitColors.sageGreen)

                            if let bio = vm.profile?.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(ChefitTypography.body())
                                    .foregroundStyle(ChefitColors.text.opacity(0.65))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, ChefitSpacing.lg)
                            }
                        }
                    }

                    if let error = vm.error {
                        Text(error)
                            .font(ChefitTypography.micro())
                            .foregroundStyle(ChefitColors.peach)
                    }

                    // Posts grid
                    if !vm.posts.isEmpty {
                        let cols = [GridItem(.flexible(), spacing: 2),
                                    GridItem(.flexible(), spacing: 2),
                                    GridItem(.flexible(), spacing: 2)]
                        LazyVGrid(columns: cols, spacing: 2) {
                            ForEach(vm.posts) { post in
                                postCell(post)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
                        .padding(.horizontal, ChefitSpacing.md)
                    }

                    Color.clear.frame(height: ChefitSpacing.twoXL)
                }
                .padding(.horizontal, ChefitSpacing.md)
            }
            .background(ChefitColors.cream.ignoresSafeArea())
            .task { await vm.load(userId: userId) }

            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ChefitColors.sageGreen)
                    .frame(width: 38, height: 38)
                    .background(ChefitColors.white.opacity(0.92))
                    .clipShape(Circle())
                    .chefitCardShadow()
            }
            .buttonStyle(.plain)
            .padding(.leading, ChefitSpacing.md)
            .padding(.top, ChefitSpacing.md)
        }
        .background(ChefitColors.cream.ignoresSafeArea())
    }

    private func postCell(_ post: Post) -> some View {
        GeometryReader { geo in
            Group {
                if let urlStr = post.imageURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else { cellPlaceholder }
                    }
                } else { cellPlaceholder }
            }
            .frame(width: geo.size.width, height: geo.size.width)
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(ChefitColors.pistachio)
            .overlay {
                Image(systemName: "person")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(ChefitColors.matcha)
            }
    }

    private var cellPlaceholder: some View {
        Rectangle()
            .fill(ChefitColors.pistachio)
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.system(size: 18, weight: .thin))
                    .foregroundStyle(ChefitColors.matcha)
            }
    }
}
