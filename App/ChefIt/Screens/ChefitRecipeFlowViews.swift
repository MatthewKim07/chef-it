import SwiftUI
import ChefItKit

struct ChefitRecipeDiscoveryView: View {
    let recipe: ChefitRecipeItem
    let onViewRecipe: () -> Void
    @State private var isFavorite: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ChefitSpacing.md) {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: recipe.imageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: ChefitRadius.md).fill(ChefitColors.pistachio)
                    }
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))

                    Text(recipe.title)
                        .font(ChefitTypography.h2())
                        .foregroundStyle(ChefitColors.white)
                        .padding(ChefitSpacing.md)
                }
                .overlay(alignment: .topTrailing) {
                    HStack(spacing: ChefitSpacing.sm) {
                        Button { isFavorite.toggle() } label: {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                        }
                        Button {} label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ChefitColors.white)
                    .padding(ChefitSpacing.md)
                }

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

                HStack {
                    Text("Ingredients")
                        .font(ChefitTypography.h3())
                        .foregroundStyle(ChefitColors.sageGreen)
                    Spacer()
                    Text("See all")
                        .font(ChefitTypography.label())
                        .foregroundStyle(ChefitColors.peach)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ChefitSpacing.sm) {
                        ForEach(ChefitSampleData.ingredientChips, id: \.0) { item in
                            ChefitIngredientChip(label: item.0, systemImage: item.1)
                        }
                    }
                }

                Button("View Recipe", action: onViewRecipe)
                    .buttonStyle(ChefitPrimaryButtonStyle())
                    .padding(.top, ChefitSpacing.md)
            }
            .padding(ChefitSpacing.md)
        }
        .background(ChefitColors.cream.ignoresSafeArea())
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
                    Image(systemName: "chevron.left")
                        .foregroundStyle(ChefitColors.sageGreen)
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

            Button {
                onStartCooking()
            } label: {
                HStack {
                    Text("Start Cooking")
                    Spacer()
                    Image(systemName: "play.fill")
                }
            }
            .buttonStyle(ChefitPrimaryButtonStyle())
            .padding(ChefitSpacing.md)
            .background(ChefitColors.cream.ignoresSafeArea())
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
