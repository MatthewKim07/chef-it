import ChefItKit
import SwiftUI

struct ChefitHomeView: View {
    @EnvironmentObject private var ingredientStore: IngredientStore
    @EnvironmentObject private var homeFeed: HomeFeedViewModel
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var userProfileStore: CurrentUserProfileStore

    let onSearchTap: () -> Void
    let onRecipeTap: (String) -> Void
    let onIngredientsTap: () -> Void
    let onCartTap: () -> Void

    private var greetingName: String {
        let trimmed = userProfileStore.profile?.displayName?.trimmingCharacters(in: .whitespaces)
        if let trimmed, !trimmed.isEmpty { return trimmed }
        return "Chef"
    }

    var body: some View {
        GeometryReader { proxy in
            let horizontalInset = max(18, proxy.size.width * 0.06)
            let recipeCardWidth = (proxy.size.width - (horizontalInset * 2) - 12) / 2
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 6) {
                        Text("Hello \(greetingName)!")
                            .font(.custom("Nunito-Bold", size: 37))
                            .foregroundStyle(ChefitColors.text)
                        Image("ChefitSplashMascot")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        Spacer()
                        Image(systemName: "bell")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundStyle(ChefitColors.text.opacity(0.85))
                    }
                    .padding(.top, 14)

                    Button(action: onSearchTap) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundStyle(ChefitColors.text.opacity(0.5))
                            Text("Search recipes, ingredients...")
                                .font(.custom("Nunito-SemiBold", size: 13))
                                .foregroundStyle(ChefitColors.text.opacity(0.35))
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 52)
                        .background(ChefitColors.white)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule().stroke(ChefitColors.text.opacity(0.07), lineWidth: 1.3)
                        }
                    }
                    .buttonStyle(.plain)

                    HStack(alignment: .top, spacing: 32) {
                        Button(action: onIngredientsTap) {
                            iconPairColumn(
                                imageName: "ChefitPantryIcon",
                                label: "Ingredients"
                            )
                        }
                        .buttonStyle(.plain)

                        Button(action: onCartTap) {
                            iconPairColumn(
                                imageName: "ChefitCartIcon",
                                label: "My Cart"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    forYouSection(recipeCardWidth: recipeCardWidth)
                }
                .padding(.horizontal, horizontalInset)
                .padding(.bottom, 20)
            }
            .background(ChefitColors.cream.ignoresSafeArea())
            .onAppear {
                homeFeed.scheduleLoad(pantryItems: ingredientStore.ingredients)
            }
            .onChange(of: ingredientStore.ingredients) { _, newValue in
                homeFeed.scheduleLoad(pantryItems: newValue)
            }
        }
    }

    @ViewBuilder
    private func iconPairColumn(imageName: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(imageName)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            Text(label)
                .font(.custom("Nunito-Bold", size: 13))
                .foregroundStyle(ChefitColors.sageGreen)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func forYouSection(recipeCardWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("For You")
                .font(.custom("Nunito-Bold", size: 36))
                .foregroundStyle(ChefitColors.text)

            Text(homeFeed.forYouSubtitle)
                .font(.custom("Nunito-SemiBold", size: 13))
                .foregroundStyle(ChefitColors.sageGreen)

            if homeFeed.isLoading && homeFeed.forYouRecipes.isEmpty {
                ProgressView()
                    .tint(ChefitColors.sageGreen)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(homeFeed.forYouRecipes) { model in
                            ChefitHomeRecipeCard(model: model) {
                                onRecipeTap(model.id)
                            }
                            .frame(width: recipeCardWidth)
                        }
                    }
                }
            }
        }
        .padding(.top, 4)
    }

}

private struct ChefitHomeRecipeCard: View {
    let model: RecipeUIModel
    var isUseSoonCard: Bool = false
    let onTap: () -> Void

    @State private var pulseWarning: Bool = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ChefitColors.cream)
                    .frame(height: 130)
                    .overlay {
                        if let imageURL = model.recipe.imageURL {
                            AsyncImage(url: imageURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Circle()
                                    .fill(ChefitColors.white)
                                    .overlay {
                                        Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                                            .font(.system(size: 50))
                                            .foregroundStyle(ChefitColors.honey)
                                    }
                            }
                        } else {
                            Circle()
                                .fill(ChefitColors.white)
                                .overlay {
                                    Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                                        .font(.system(size: 50))
                                        .foregroundStyle(ChefitColors.honey)
                                }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        Text("🥦 \(model.matchPercentText)")
                            .font(.custom("Nunito-Bold", size: 11))
                            .foregroundStyle(ChefitColors.sageGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(ChefitColors.white.opacity(0.95))
                            .clipShape(Capsule())
                            .padding(8)
                    }
                    .overlay(alignment: .topTrailing) {
                        Text(model.contextBadge)
                            .font(.custom("Nunito-Bold", size: 11))
                            .foregroundStyle(ChefitColors.sageGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(ChefitColors.white.opacity(0.95))
                            .clipShape(Capsule())
                            .padding(8)
                    }

                Text(model.recipe.title)
                    .font(.custom("Nunito-Bold", size: 14))
                    .foregroundStyle(ChefitColors.text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2, reservesSpace: true)

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                    Text("\(model.recipe.cookingMinutes) min")
                    Text("•")
                    Text(model.badges.contains(.onePan) ? "1 pan" : model.recipe.difficulty.rawValue.capitalized)
                }
                .font(.custom("Nunito-SemiBold", size: 11))
                .foregroundStyle(ChefitColors.matcha)

                HStack(spacing: 6) {
                    ForEach(model.previewIngredients, id: \.self) { ingredient in
                        Image(systemName: symbol(for: ingredient))
                            .font(.system(size: 13))
                            .foregroundStyle(ChefitColors.sageGreen)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                        .scaleEffect(pulseWarning ? 1.2 : 0.8)
                    Text("\(model.expiringIngredient ?? "") expiring")
                        .font(.custom("Nunito-Bold", size: 11))
                        .foregroundStyle(Color.orange)
                }
                .opacity(model.expiringIngredient == nil ? 0 : 1)
            }
            .padding(10)
            .background(ChefitColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isUseSoonCard
                            ? Color.orange.opacity(0.35)
                            : ChefitColors.text.opacity(0.12),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            if isUseSoonCard {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    pulseWarning = true
                }
            }
        }
    }

    private func symbol(for ingredient: String) -> String {
        switch ingredient.lowercased() {
        case "tomato": return ChefitSymbol.tomato
        case "garlic": return ChefitSymbol.garlic
        case "olive oil": return ChefitSymbol.oliveOil
        case "pasta": return ChefitSymbol.pasta
        case "broccoli": return ChefitSymbol.broccoli
        case "milk": return ChefitSymbol.milk
        case "chicken": return ChefitSymbol.chicken
        case "onion": return ChefitSymbol.onion
        default: return "leaf.fill"
        }
    }
}

struct ChefitMyIngredientsView: View {
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("My Ingredients")
                    .font(.custom("Nunito-Bold", size: 22))
                    .foregroundStyle(ChefitColors.text)

                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(ChefitColors.sageGreen)
                            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                    Spacer()
                }
            }
            .padding(.horizontal, ChefitSpacing.md)
            .padding(.top, ChefitSpacing.sm)
            .padding(.bottom, ChefitSpacing.md)

            Spacer(minLength: 8)

            Image("ChefitIngredientsPantryHero")
                .renderingMode(.original)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, ChefitSpacing.md)

            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChefitColors.cream.ignoresSafeArea())
    }
}

struct ChefitSearchView: View {
    let onResultTap: (String) -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ChefitSpacing.lg) {
                HStack(spacing: ChefitSpacing.sm) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(ChefitColors.sageGreen)
                            .frame(width: 44, height: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    ChefitSearchBar(
                        placeholder: "Search recipes, ingredients…",
                        showsFilter: true,
                        onTap: {}
                    )
                }

                sectionLabel("Recent Searches")
                FlowLayout(spacing: ChefitSpacing.sm) {
                    ForEach(["pasta", "chicken", "salmon"], id: \.self) { term in
                        Text(term)
                            .font(ChefitTypography.label())
                            .foregroundStyle(ChefitColors.sageGreen)
                            .padding(.horizontal, ChefitSpacing.sm)
                            .padding(.vertical, ChefitSpacing.xs)
                            .background(ChefitColors.pistachio)
                            .clipShape(Capsule())
                    }
                }

                sectionLabel("Browse Categories")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: ChefitSpacing.md) {
                    ChefitCategoryBubble(systemImage: ChefitSymbol.quickEasy, label: "Quick & Easy") { onResultTap("creamy-pasta") }
                    ChefitCategoryBubble(systemImage: ChefitSymbol.vegetarian, label: "Vegetarian") { onResultTap("veggie-stir-fry") }
                    ChefitCategoryBubble(systemImage: ChefitSymbol.dinner, label: "Dinner") { onResultTap("tomato-broccoli-pasta") }
                    ChefitCategoryBubble(systemImage: ChefitSymbol.breakfast, label: "Breakfast") { onResultTap("creamy-pasta") }
                }

                sectionLabel("Trending Ingredients")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ChefitSpacing.sm) {
                        ForEach(
                            [
                                (ChefitSymbol.tomato, "Tomato"),
                                (ChefitSymbol.chicken, "Chicken"),
                                (ChefitSymbol.avocado, "Avocado"),
                                (ChefitSymbol.broccoli, "Broccoli")
                            ],
                            id: \.1
                        ) { item in
                            Button {
                                onResultTap("creamy-pasta")
                            } label: {
                                ChefitIngredientChip(label: item.1, systemImage: item.0)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(ChefitSpacing.md)
        }
        .background(ChefitColors.cream.ignoresSafeArea())
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(ChefitTypography.label())
            .foregroundStyle(ChefitColors.sageGreen)
    }
}
