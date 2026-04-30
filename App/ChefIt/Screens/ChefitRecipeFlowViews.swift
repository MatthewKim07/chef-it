import ChefItKit
import SwiftUI

struct ChefitRecipeDetailsPayload: Hashable {
    let id: String
    let title: String
    let imageURL: URL?
    let minutes: Int
    let difficulty: String
    let servings: Int
    let ingredients: [String]
    let blurb: String
    let sourceURL: URL?

    static func fromSample(_ recipe: ChefitRecipeItem) -> ChefitRecipeDetailsPayload {
        ChefitRecipeDetailsPayload(
            id: recipe.id,
            title: recipe.title,
            imageURL: recipe.imageURL,
            minutes: recipe.minutes,
            difficulty: recipe.difficulty,
            servings: 2,
            ingredients: ChefitSampleData.recipeDetailIngredients.map(\.1),
            blurb: "A chef-it favorite built from your pantry-ready picks.",
            sourceURL: nil
        )
    }

    static func fromRecipe(_ recipe: Recipe) -> ChefitRecipeDetailsPayload {
        ChefitRecipeDetailsPayload(
            id: recipe.id,
            title: recipe.title,
            imageURL: recipe.imageURL,
            minutes: recipe.cookingMinutes,
            difficulty: recipe.difficulty.rawValue.capitalized,
            servings: recipe.servings,
            ingredients: recipe.ingredients,
            blurb: recipe.blurb,
            sourceURL: recipe.sourceURL
        )
    }
}

struct ChefitRecipeDiscoveryView: View {
    let recipe: ChefitRecipeItem
    let onViewRecipe: () -> Void

    @EnvironmentObject private var shoppingCart: ShoppingCartViewModel
    @EnvironmentObject private var ingredientStore: IngredientStore

    @State private var isFavorite: Bool = false
    @State private var showCartSheet = false

    private struct IngredientStatus: Hashable {
        let name: String
        let symbol: String
        let quantity: String
        let isAvailable: Bool
    }

    private var ingredientStatuses: [IngredientStatus] {
        let normalizer = IngredientNormalizer()
        let pantry = ingredientStore.canonicalSet
        var seen = Set<String>()
        var rows: [IngredientStatus] = []
        for (symbol, name, qty) in ChefitSampleData.ingredientRows(forRecipeId: recipe.id) {
            let canonical = normalizer.canonicalize(name)
            guard !seen.contains(canonical) else { continue }
            seen.insert(canonical)
            rows.append(
                IngredientStatus(
                    name: name,
                    symbol: symbol,
                    quantity: qty,
                    isAvailable: pantry.contains(canonical)
                )
            )
        }
        return rows.sorted { ($0.isAvailable ? 0 : 1, $0.name) < ($1.isAvailable ? 0 : 1, $1.name) }
    }

    private var availableCount: Int { ingredientStatuses.filter(\.isAvailable).count }
    private var totalCount: Int { ingredientStatuses.count }
    private var missingCount: Int { totalCount - availableCount }
    private var hasEverything: Bool { missingCount == 0 && totalCount > 0 }

    private var matchPercent: Int {
        guard totalCount > 0 else { return 0 }
        return Int((Double(availableCount) / Double(totalCount) * 100).rounded())
    }

    private var heroBadgeText: String {
        if hasEverything { return "Ready to cook" }
        if matchPercent >= 60 { return "\(matchPercent)% Match" }
        if recipe.minutes <= 20 { return "Quick" }
        return "Popular"
    }

    private var pantryHeadline: String {
        if totalCount == 0 { return "Pantry match" }
        if hasEverything { return "You've got everything you need" }
        if missingCount == 1 { return "You're 1 ingredient away" }
        return "You're \(missingCount) ingredients away"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.md) {
            heroSection
            metadataRow
            pantrySection
            actionStack
        }
        .padding(.horizontal, ChefitSpacing.md)
        .padding(.top, ChefitSpacing.sm)
        .padding(.bottom, ChefitSpacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ChefitColors.cream.ignoresSafeArea())
        .sheet(isPresented: $showCartSheet) {
            NavigationStack {
                ChefitShoppingListView(showDismissButton: true)
                    .environmentObject(shoppingCart)
            }
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: recipe.imageURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: ChefitRadius.lg).fill(ChefitColors.pistachio)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.lg, style: .continuous))

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.05),
                    .black.opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.lg, style: .continuous))

            Text(recipe.title)
                .font(ChefitTypography.h2())
                .foregroundStyle(ChefitColors.white)
                .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 2)
                .padding(.horizontal, ChefitSpacing.md)
                .padding(.bottom, ChefitSpacing.sm)
        }
        .frame(height: 200)
        .overlay(alignment: .topLeading) {
            heroBadge
                .padding(ChefitSpacing.md)
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: ChefitSpacing.sm) {
                circularGlassButton(systemName: isFavorite ? "heart.fill" : "heart") {
                    isFavorite.toggle()
                }
                circularGlassButton(systemName: "ellipsis") {}
            }
            .padding(ChefitSpacing.md)
        }
    }

    private var heroBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: hasEverything ? "checkmark.circle.fill" : "sparkles")
                .font(.system(size: 11, weight: .bold))
            Text(heroBadgeText)
                .font(ChefitTypography.micro())
                .fontWeight(.bold)
        }
        .foregroundStyle(ChefitColors.sageGreen)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(ChefitColors.white.opacity(0.92))
        .clipShape(Capsule(style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 1)
    }

    private func circularGlassButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ChefitColors.white)
                .frame(width: 34, height: 34)
                .background(.ultraThinMaterial, in: Circle())
                .background(Color.black.opacity(0.18), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var metadataRow: some View {
        HStack(spacing: ChefitSpacing.sm) {
            metadataPill(symbol: ChefitSymbol.clock, text: "\(recipe.minutes) min")
            metadataPill(symbol: ChefitSymbol.star, text: recipe.difficulty)
            metadataPill(symbol: ChefitSymbol.personServings, text: "2 servings")
            Spacer(minLength: 0)
        }
    }

    private func metadataPill(symbol: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(ChefitTypography.label())
        }
        .foregroundStyle(ChefitColors.sageGreen)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(ChefitColors.pistachio.opacity(0.7))
        .clipShape(Capsule(style: .continuous))
    }

    private var pantrySection: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Based on your pantry")
                    .font(ChefitTypography.micro())
                    .fontWeight(.semibold)
                    .foregroundStyle(ChefitColors.matcha)
                    .textCase(.uppercase)
                    .tracking(0.6)
                Text(pantryHeadline)
                    .font(ChefitTypography.h3())
                    .foregroundStyle(ChefitColors.sageGreen)
            }

            progressIndicator

            if availableCount > 0 {
                ingredientGroup(
                    title: "In your pantry",
                    countText: "\(availableCount)",
                    items: ingredientStatuses.filter(\.isAvailable),
                    available: true
                )
            }

            if missingCount > 0 {
                ingredientGroup(
                    title: "You're missing",
                    countText: "\(missingCount)",
                    items: ingredientStatuses.filter { !$0.isAvailable },
                    available: false
                )
            }
        }
        .padding(ChefitSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ChefitColors.white)
        .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.lg, style: .continuous))
        .chefitCardShadow()
    }

    private var progressIndicator: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(availableCount)/\(totalCount) ingredients available")
                    .font(ChefitTypography.label())
                    .foregroundStyle(ChefitColors.sageGreen)
                Spacer()
                Text("\(matchPercent)%")
                    .font(ChefitTypography.label())
                    .foregroundStyle(ChefitColors.peach)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(ChefitColors.pistachio)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [ChefitColors.matcha, ChefitColors.sageGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(max(0, min(1, Double(availableCount) / Double(max(totalCount, 1))))))
                }
            }
            .frame(height: 8)
        }
    }

    private func ingredientGroup(
        title: String,
        countText: String,
        items: [IngredientStatus],
        available: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
            HStack(spacing: 6) {
                Text(title)
                    .font(ChefitTypography.label())
                    .foregroundStyle(available ? ChefitColors.sageGreen : ChefitColors.matcha)
                Text(countText)
                    .font(ChefitTypography.micro())
                    .fontWeight(.bold)
                    .foregroundStyle(available ? ChefitColors.sageGreen : ChefitColors.matcha)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(
                            (available ? ChefitColors.matcha : ChefitColors.pistachio).opacity(available ? 0.35 : 1)
                        )
                    )
                Spacer()
            }
            FlowLayout(spacing: ChefitSpacing.sm) {
                ForEach(items, id: \.self) { item in
                    statusChip(item)
                }
            }
        }
    }

    private func statusChip(_ item: IngredientStatus) -> some View {
        let foreground = item.isAvailable ? ChefitColors.sageGreen : ChefitColors.matcha
        let background = item.isAvailable ? ChefitColors.matcha.opacity(0.22) : ChefitColors.pistachio.opacity(0.55)
        let border = item.isAvailable ? ChefitColors.matcha.opacity(0.55) : ChefitColors.matcha.opacity(0.25)
        return HStack(spacing: 6) {
            Image(systemName: item.symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(foreground)
            Text(item.name)
                .font(ChefitTypography.label())
                .foregroundStyle(foreground)
            Text(item.quantity)
                .font(ChefitTypography.micro())
                .foregroundStyle(foreground.opacity(0.75))
            Image(systemName: item.isAvailable ? "checkmark.circle.fill" : "plus.circle")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(foreground.opacity(item.isAvailable ? 1 : 0.7))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(background)
        .overlay(
            Capsule(style: .continuous).stroke(border, lineWidth: 1)
        )
        .clipShape(Capsule(style: .continuous))
        .opacity(item.isAvailable ? 1 : 0.95)
    }

    @ViewBuilder
    private var actionStack: some View {
        VStack(spacing: ChefitSpacing.sm) {
            if hasEverything {
                Button(action: onViewRecipe) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Cooking")
                    }
                }
                .buttonStyle(ChefitPrimaryButtonStyle())
            } else {
                Button {
                    shoppingCart.loadFromRecipe(
                        recipeId: recipe.id,
                        pantryCanonical: ingredientStore.canonicalSet
                    )
                    showCartSheet = true
                } label: {
                    HStack {
                        Image(systemName: "cart.badge.plus")
                        Text("Grab what you're missing")
                    }
                }
                .buttonStyle(ChefitPrimaryButtonStyle())
            }

            Button(action: onViewRecipe) {
                Text("View Recipe")
            }
            .buttonStyle(ChefitSecondaryButtonStyle())
        }
    }
}

@MainActor
private final class RecipeReviewsViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load(recipeId: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            reviews = try await ReviewService.shared.fetchReviews(recipeId: recipeId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func upsert(_ review: Review) {
        if let index = reviews.firstIndex(where: { $0.userId == review.userId }) {
            reviews[index] = review
        } else {
            reviews.insert(review, at: 0)
        }
        reviews.sort { $0.createdAt > $1.createdAt }
    }
}

struct ChefitRecipeDetailsView: View {
    enum RecipeTab: String, CaseIterable {
        case ingredients = "Ingredients"
        case steps = "Steps"
        case notes = "Notes"
        case reviews = "Reviews"
    }

    let recipe: ChefitRecipeItem
    let onBack: () -> Void
    let onStartCooking: () -> Void

    @EnvironmentObject private var authService: AuthService
    @StateObject private var reviewsVM = RecipeReviewsViewModel()
    @State private var selectedTab: RecipeTab = .ingredients
    @State private var showReviewComposer = false

    private var currentUserId: Int? { authService.currentUser?.id }
    private var currentUserReview: Review? {
        guard let currentUserId else { return nil }
        return reviewsVM.reviews.first(where: { $0.userId == currentUserId })
    }
    private var averageRating: Double {
        guard !reviewsVM.reviews.isEmpty else { return 0 }
        let total = reviewsVM.reviews.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(reviewsVM.reviews.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: ChefitSpacing.md) {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(ChefitColors.sageGreen)
                            .frame(width: 44, height: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .foregroundStyle(ChefitColors.sageGreen)
                }

                headerCard
                tabSelector

                ScrollView {
                    tabContent
                        .padding(.bottom, ChefitSpacing.twoXL + ChefitSpacing.lg)
                }
            }
            .padding(ChefitSpacing.md)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                onStartCooking()
            } label: {
                HStack {
                    Text("Start Cooking")
                    Spacer()
                    Image(systemName: "play.fill")
                }
                .padding(.horizontal, ChefitSpacing.sm)
            }
            .buttonStyle(ChefitPrimaryButtonStyle())
            .padding(ChefitSpacing.md)
            .background(ChefitColors.cream.ignoresSafeArea(edges: .bottom))
        }
        .background(ChefitColors.cream.ignoresSafeArea())
        .task { await reviewsVM.load(recipeId: recipe.id) }
        .sheet(isPresented: $showReviewComposer) {
            ReviewComposerSheet(
                recipeId: recipe.id,
                currentUserId: currentUserId
            ) { review in
                reviewsVM.upsert(review)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
            Text(recipe.title)
                .font(ChefitTypography.h2())
                .foregroundStyle(ChefitColors.sageGreen)

            HStack(spacing: 6) {
                Image(systemName: ChefitSymbol.clock)
                Text("\(recipe.minutes) min")
                Text("·").foregroundStyle(ChefitColors.matcha.opacity(0.55))
                Image(systemName: ChefitSymbol.star)
                Text(recipe.difficulty)
                Text("·").foregroundStyle(ChefitColors.matcha.opacity(0.55))
                Image(systemName: ChefitSymbol.personServings)
                Text("2 servings")
            }
            .font(ChefitTypography.micro())
            .foregroundStyle(ChefitColors.matcha)
        }
    }

    private var tabSelector: some View {
        HStack(spacing: ChefitSpacing.md) {
            ForEach(RecipeTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Text(tab.rawValue)
                            .font(ChefitTypography.label())
                            .foregroundStyle(selectedTab == tab ? ChefitColors.sageGreen : ChefitColors.matcha)
                        Rectangle()
                            .fill(selectedTab == tab ? ChefitColors.peach : .clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .ingredients:
            VStack(spacing: 0) {
                ForEach(ChefitSampleData.recipeDetailIngredients, id: \.1) { item in
                    HStack {
                        Image(systemName: item.0)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(ChefitColors.matcha)
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 28, alignment: .center)
                        Text(item.1)
                            .font(ChefitTypography.body())
                            .foregroundStyle(ChefitColors.sageGreen)
                        Spacer()
                        Text(item.2)
                            .font(ChefitTypography.label())
                            .foregroundStyle(ChefitColors.matcha)
                    }
                    .padding(.vertical, ChefitSpacing.sm)
                    Divider().overlay(ChefitColors.pistachio)
                }
            }
        case .steps:
            VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
                ChefitStepRow(stepNumber: 1, text: "Boil the pasta", systemImage: ChefitSymbol.stepBoilPasta)
                ChefitStepRow(stepNumber: 2, text: "Sauté garlic", systemImage: ChefitSymbol.stepSaute)
                ChefitStepRow(stepNumber: 3, text: "Add tomatoes", systemImage: ChefitSymbol.stepTomatoes)
                ChefitStepRow(stepNumber: 4, text: "Combine and serve", systemImage: ChefitSymbol.stepServe)
            }
        case .notes:
            Text("No notes yet. Add your own tips here.")
                .font(ChefitTypography.body())
                .foregroundStyle(ChefitColors.matcha)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, ChefitSpacing.sm)
        case .reviews:
            reviewsContent
        }
    }

    private var reviewsContent: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.md) {
            reviewSummaryCard

            Button(currentUserReview == nil ? "Write Review" : "Update Review") {
                showReviewComposer = true
            }
            .buttonStyle(ChefitSecondaryButtonStyle())

            if reviewsVM.isLoading {
                HStack {
                    Spacer()
                    ProgressView().tint(ChefitColors.sageGreen)
                    Spacer()
                }
                .padding(.vertical, ChefitSpacing.xl)
            } else if let errorMessage = reviewsVM.errorMessage {
                Text(errorMessage)
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.peach)
            } else if reviewsVM.reviews.isEmpty {
                VStack(spacing: ChefitSpacing.sm) {
                    Image(systemName: "star.bubble")
                        .font(.system(size: 30, weight: .thin))
                        .foregroundStyle(ChefitColors.matcha)
                    Text("No reviews yet")
                        .font(ChefitTypography.h3())
                        .foregroundStyle(ChefitColors.sageGreen)
                    Text("Be the first Chef to share how it tasted.")
                        .font(ChefitTypography.body())
                        .foregroundStyle(ChefitColors.matcha)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ChefitSpacing.xl)
            } else {
                LazyVStack(spacing: ChefitSpacing.md) {
                    ForEach(reviewsVM.reviews) { review in
                        ReviewRowView(review: review)
                    }
                }
            }
        }
    }

    private var reviewSummaryCard: some View {
        HStack(spacing: ChefitSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(reviewsVM.reviews.isEmpty ? "Recipe Reviews" : String(format: "%.1f ★", averageRating))
                    .font(ChefitTypography.h3())
                    .foregroundStyle(ChefitColors.sageGreen)
                Text(reviewsVM.reviews.isEmpty ? "No ratings yet" : "\(reviewsVM.reviews.count) Chef reviews")
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.matcha)
            }

            Spacer()

            Image(systemName: "star.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(ChefitColors.honey)
        }
        .padding(ChefitSpacing.md)
        .background(ChefitColors.white)
        .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
        .chefitCardShadow()
    }
}