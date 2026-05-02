import SwiftUI
import ChefItKit

enum ChefitRoute: Hashable {
    case home
    case myIngredients
    case search
    case recipeDiscover(id: String)
    case recipeDetails(payload: ChefitRecipeDetailsPayload)
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
    @EnvironmentObject private var homeFeed: HomeFeedViewModel
    @EnvironmentObject private var userProfileStore: CurrentUserProfileStore
    @State private var route: ChefitRoute = .home
    @State private var selectedTab: ChefitTab = .home
    @State private var shoppingListOrigin: ChefitRoute = .home
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var pendingImageData: Data?
    @State private var pendingSource: ScanSourceKind = .camera
    @State private var scanErrorMessage: String?
    @StateObject private var scanVM = ScanFlowViewModel(
        ingredientStore: IngredientStore.live(),
        scanService: VisionScanService()
    )
    @StateObject private var recommendationsVM = RecommendationsViewModel(
        ingredientStore: IngredientStore.live()
    )

    private var profileAvatarURL: URL? {
        guard let urlStr = userProfileStore.profile?.avatarURL else { return nil }
        return URL(string: urlStr)
    }

    var body: some View {
        routeView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ChefitColors.cream.ignoresSafeArea(edges: .all))
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if showsBottomNav {
                    ChefitBottomNavBar(
                        activeTab: selectedTab,
                        profileAvatarURL: profileAvatarURL
                    ) { tab in
                        selectedTab = tab
                        switch tab {
                        case .home:
                            route = .home
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
            .fullScreenCover(isPresented: $showCamera, onDismiss: startPendingScan) {
                CameraCapture(
                    sourceType: .camera,
                    onImageCaptured: { imageData in
                        pendingImageData = imageData
                        pendingSource = .camera
                        showCamera = false
                    },
                    onCancel: { showCamera = false }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showPhotoLibrary, onDismiss: startPendingScan) {
                CameraCapture(
                    sourceType: .photoLibrary,
                    onImageCaptured: { imageData in
                        pendingImageData = imageData
                        pendingSource = .photoLibrary
                        showPhotoLibrary = false
                    },
                    onCancel: { showPhotoLibrary = false }
                )
            }
            .onChange(of: route) { _, newValue in
                switch newValue {
                case .home, .myIngredients, .search: selectedTab = .home
                case .scan, .detectedIngredients, .recommendations: selectedTab = .scan
                case .community, .userProfile: selectedTab = .community
                case .profile: selectedTab = .profile
                default: break
                }
                if case .recommendations = newValue {
                    Task { await recommendationsVM.refresh() }
                }
            }
            .onChange(of: scanVM.phase) { _, phase in
                switch phase {
                case .review, .empty:
                    route = .detectedIngredients
                case .failed:
                    scanErrorMessage = scanVM.message ?? "Scan failed. Check Xcode console for details."
                default:
                    break
                }
            }
            .alert("Scan Failed", isPresented: Binding(
                get: { scanErrorMessage != nil },
                set: { if !$0 { scanErrorMessage = nil; scanVM.reset() } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(scanErrorMessage ?? "")
            }
    }

    private func startPendingScan() {
        guard let data = pendingImageData else { return }
        let source = pendingSource
        pendingImageData = nil
        Task { await scanVM.beginScan(imageData: data, source: source) }
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
                onRecipeTap: { recipeID in route = .recipeDiscover(id: recipeID) },
                onIngredientsTap: { route = .myIngredients },
                onCartTap: {
                    shoppingListOrigin = .home
                    route = .shoppingList
                }
            )

        case .myIngredients:
            ChefitMyIngredientsView {
                route = .home
            }

        case .search:
            ChefitSearchView(
                onResultTap: { recipeID in
                    route = .recipeDiscover(id: recipeID)
                },
                onBack: {
                    route = .home
                }
            )

        case .recipeDiscover(let id):
            let recipe = homeFeed.recipeByID[id]
                ?? ChefitSampleData.popularRecipes.first(where: { $0.id == id })
                ?? ChefitSampleData.popularRecipes[0]
            ChefitRecipeDiscoveryView(recipe: recipe) { payload in
                route = .recipeDetails(payload: payload)
            }

        case .recipeDetails(let payload):
            ChefitRecipeDetailsView(
                recipe: payload,
                onBack: {
                    let hasMainRecipe = homeFeed.recipeByID[payload.id] != nil
                        || ChefitSampleData.popularRecipes.contains(where: { $0.id == payload.id })
                    route = hasMainRecipe ? .recipeDiscover(id: payload.id) : .recommendations
                }
            )

        case .scan:
            ChefitScanPantryView(
                previewImageData: pendingImageData ?? scanVM.draft?.imageData,
                isAnalyzing: scanVM.phase == .analyzing,
                onScanNow: { showCamera = true },
                onAddManually: { showPhotoLibrary = true }
            )

        case .detectedIngredients:
            ChefitDetectedIngredientsView(
                candidates: scanVM.candidates,
                message: scanVM.message,
                onToggleCandidate: scanVM.toggleCandidate,
                onAddManualCandidate: scanVM.addManualCandidate,
                onFindRecipes: {
                    if scanVM.confirmSelected() {
                        route = .recommendations
                    }
                }
            )

        case .recommendations:
            ChefitRecommendationsView(
                vm: recommendationsVM,
                onRecipeTap: { recipe in
                    route = .recipeDetails(payload: .fromRecipe(recipe))
                }
            )

        case .shoppingList:
            ChefitShoppingListView(onBack: { route = shoppingListOrigin })

        case .saved:
            ChefitSavedView { recipeID in
                route = .recipeDiscover(id: recipeID)
            }

        case .profile:
            ChefitProfileView(
                onShoppingTap: {
                    shoppingListOrigin = .profile
                    route = .shoppingList
                },
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
        async let postsTask = PostService.shared.fetchPosts(userId: userId)
        do {
            let (p, pg) = try await (profileTask, postsTask)
            profile = p
            posts = pg.posts
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

                    Group {
                        if let urlStr = vm.profile?.avatarURL, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().scaledToFill()
                                } else {
                                    avatarPlaceholder
                                }
                            }
                        } else {
                            avatarPlaceholder
                        }
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

                    if !vm.posts.isEmpty {
                        let cols = [
                            GridItem(.flexible(), spacing: 2),
                            GridItem(.flexible(), spacing: 2),
                            GridItem(.flexible(), spacing: 2)
                        ]
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
                        } else {
                            cellPlaceholder
                        }
                    }
                } else {
                    cellPlaceholder
                }
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
