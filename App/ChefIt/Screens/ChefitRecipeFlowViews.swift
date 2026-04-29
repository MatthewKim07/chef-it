import SwiftUI

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

                Text("🕐 \(recipe.minutes) min · ⭐ \(recipe.difficulty) · 👤 2 servings")
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
                            ChefitIngredientChip(label: item.0, icon: item.1)
                        }
                    }
                }

                Button("View Recipe", action: onViewRecipe)
                    .buttonStyle(ChefitPrimaryButtonStyle())
                    .padding(.top, ChefitSpacing.md)
            }
            .padding(ChefitSpacing.md)
            .padding(.bottom, 90)
        }
        .background(ChefitColors.cream)
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
                        .padding(.bottom, 100)
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
            .background(ChefitColors.cream)
        }
        .background(ChefitColors.cream)
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
                        Text(item.0)
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
                ChefitStepRow(stepNumber: 1, text: "Boil the pasta", icon: "🍝")
                ChefitStepRow(stepNumber: 2, text: "Sauté garlic", icon: "🧄")
                ChefitStepRow(stepNumber: 3, text: "Add tomatoes", icon: "🍅")
                ChefitStepRow(stepNumber: 4, text: "Combine and serve", icon: "🍽️")
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
