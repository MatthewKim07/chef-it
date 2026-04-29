import SwiftUI

struct ChefitHomeView: View {
    let onSearchTap: () -> Void
    let onRecipeTap: (String) -> Void
    @State private var favorites: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ChefitSpacing.lg) {
                HStack {
                    Text("Hello Chef! ❤️")
                        .font(ChefitTypography.h2())
                        .foregroundStyle(ChefitColors.sageGreen)
                    Spacer()
                    Image(systemName: "bell")
                        .foregroundStyle(ChefitColors.sageGreen)
                        .overlay(alignment: .topTrailing) {
                            Circle().fill(ChefitColors.peach).frame(width: 8, height: 8)
                        }
                }

                ChefitSearchBar(
                    placeholder: "Search recipes, ingredients…",
                    showsFilter: false,
                    onTap: onSearchTap
                )

                HStack {
                    VStack(alignment: .leading, spacing: ChefitSpacing.xs) {
                        Text("What's for dinner?")
                            .font(ChefitTypography.h3())
                            .foregroundStyle(ChefitColors.sageGreen)
                        Text("Get ideas")
                            .font(ChefitTypography.label())
                            .foregroundStyle(ChefitColors.peach)
                            .underline()
                    }
                    Spacer()
                    Text("🍜")
                        .font(.system(size: 40))
                }
                .padding(ChefitSpacing.md)
                .background(ChefitColors.pistachio)
                .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))

                ChefitSectionHeader(title: "Popular Recipes")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ChefitSpacing.md) {
                        ForEach(ChefitSampleData.popularRecipes) { recipe in
                            ChefitRecipeCard(
                                title: recipe.title,
                                imageURL: recipe.imageURL,
                                cookingMinutes: recipe.minutes,
                                difficulty: recipe.difficulty,
                                isFavorite: Binding(
                                    get: { favorites.contains(recipe.id) },
                                    set: { isOn in
                                        if isOn { favorites.insert(recipe.id) }
                                        else { favorites.remove(recipe.id) }
                                    }
                                ),
                                onTap: { onRecipeTap(recipe.id) }
                            )
                            .frame(width: 220)
                        }
                    }
                }
            }
            .padding(ChefitSpacing.md)
            .padding(.bottom, 90)
        }
        .background(ChefitColors.cream)
    }
}

struct ChefitSearchView: View {
    let onResultTap: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ChefitSpacing.lg) {
                HStack(spacing: ChefitSpacing.sm) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(ChefitColors.sageGreen)
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
                    ChefitCategoryBubble(icon: "⚡️", label: "Quick & Easy") { onResultTap("creamy-pasta") }
                    ChefitCategoryBubble(icon: "🥗", label: "Vegetarian") { onResultTap("veggie-stir-fry") }
                    ChefitCategoryBubble(icon: "🍽️", label: "Dinner") { onResultTap("tomato-broccoli-pasta") }
                    ChefitCategoryBubble(icon: "🍳", label: "Breakfast") { onResultTap("creamy-pasta") }
                }

                sectionLabel("Trending Ingredients")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ChefitSpacing.sm) {
                        ForEach([("🍅", "Tomato"), ("🍗", "Chicken"), ("🥑", "Avocado"), ("🥦", "Broccoli")], id: \.1) { item in
                            Button {
                                onResultTap("creamy-pasta")
                            } label: {
                                ChefitIngredientChip(label: item.1, icon: item.0)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(ChefitSpacing.md)
            .padding(.bottom, 90)
        }
        .background(ChefitColors.cream)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(ChefitTypography.label())
            .foregroundStyle(ChefitColors.sageGreen)
    }
}
