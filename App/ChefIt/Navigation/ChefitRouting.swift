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
    @State private var route: ChefitRoute = .home
    @State private var selectedTab: ChefitTab = .home
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

    var body: some View {
        routeView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChefitColors.cream.ignoresSafeArea(edges: .all))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsBottomNav {
                ChefitBottomNavBar(activeTab: selectedTab) { tab in
                    selectedTab = tab
                    switch tab {
                    case .home:      route = .home
                    case .search:    route = .search
                    case .scan:      route = .scan
                    case .community: route = .community
                    case .profile:   route = .profile
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
            case .home:     selectedTab = .home
            case .search:   selectedTab = .search
            case .scan, .detectedIngredients, .recommendations: selectedTab = .scan
            case .community: selectedTab = .community
            case .profile:  selectedTab = .profile
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
            default: break
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
                onRecipeTap: { recipeID in route = .recipeDiscover(id: recipeID) }
            )
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
