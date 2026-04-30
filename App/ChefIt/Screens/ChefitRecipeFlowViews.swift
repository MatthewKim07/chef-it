import ChefItKit
import SwiftUI

struct ChefitRecipeDiscoveryView: View {
    let recipe: ChefitRecipeItem
    let onViewRecipe: () -> Void

    @EnvironmentObject private var shoppingCart: ShoppingCartViewModel
    @EnvironmentObject private var ingredientStore: IngredientStore

    @State private var isFavorite: Bool = false
    @State private var showCartSheet = false

    private var missingIngredientNames: [String] {
        ShoppingListBuilder.missingIngredientDisplayNames(
            recipeIngredientNames: ChefitSampleData.ingredientDisplayNames(forRecipeId: recipe.id),
            pantryCanonical: ingredientStore.canonicalSet
        )
    }

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

                missingIngredientsSection

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
                        ForEach(ChefitSampleData.ingredientChips(forRecipeId: recipe.id), id: \.0) { item in
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
        .sheet(isPresented: $showCartSheet) {
            NavigationStack {
                ChefitShoppingListView(showDismissButton: true)
                    .environmentObject(shoppingCart)
            }
        }
    }

    @ViewBuilder
    private var missingIngredientsSection: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
            Text("Missing Ingredients")
                .font(ChefitTypography.h3())
                .foregroundStyle(ChefitColors.sageGreen)

            if missingIngredientNames.isEmpty {
                Text("You've got what this recipe needs in your pantry.")
                    .font(ChefitTypography.body())
                    .foregroundStyle(ChefitColors.matcha)
            } else {
                FlowLayout(spacing: ChefitSpacing.sm) {
                    ForEach(missingIngredientNames, id: \.self) { name in
                        Text(name)
                            .font(ChefitTypography.label())
                            .foregroundStyle(ChefitColors.sageGreen)
                            .padding(.horizontal, ChefitSpacing.sm)
                            .padding(.vertical, ChefitSpacing.xs)
                            .background(ChefitColors.pistachio)
                            .clipShape(Capsule())
                    }
                }

                Button {
                    shoppingCart.loadFromRecipe(recipeId: recipe.id, pantryCanonical: ingredientStore.canonicalSet)
                    showCartSheet = true
                } label: {
                    Label("Add to Cart", systemImage: "cart.badge.plus")
                }
                .buttonStyle(ChefitSecondaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ChefitRecipeDetailsView: View {
    enum RecipeTab: String, CaseIterable {
        case ingredients = "Ingredients"
        case steps = "Steps"
        case notes = "Notes"
    }

    let onStartCooking: () -> Void
    @State private var selectedTab: RecipeTab = .ingredients

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
        }
    }
}
