import SwiftUI

struct ChefitHomeView: View {
    let onSearchTap: () -> Void
    let onRecipeTap: (String) -> Void

    var body: some View {
        GeometryReader { proxy in
            let horizontalInset = max(18, proxy.size.width * 0.06)
            let cardHeight = proxy.size.height * 0.145
            let recipeCardWidth = (proxy.size.width - (horizontalInset * 2) - 12) / 2
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 6) {
                        Text("Hello Chef!")
                            .font(.custom("Nunito-Bold", size: 37))
                            .foregroundStyle(ChefitColors.text)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(ChefitColors.peach)
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

                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("What's for\ndinner?")
                                .font(.custom("PlayfairDisplay-Bold", size: 26))
                                .foregroundStyle(ChefitColors.text)
                                .lineSpacing(1)
                            Text("Get ideas")
                                .font(.custom("Nunito-Bold", size: 13))
                                .foregroundStyle(ChefitColors.sageGreen)
                        }
                        Spacer()
                        Circle()
                            .fill(ChefitColors.white)
                            .frame(width: 104, height: 104)
                            .overlay {
                                Image(systemName: "bowl.fill")
                                    .font(.system(size: 56))
                                    .foregroundStyle(ChefitColors.honey)
                            }
                            .overlay(alignment: .top) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(ChefitColors.matcha)
                                    .offset(y: -8)
                            }
                    }
                    .padding(.horizontal, 18)
                    .frame(height: cardHeight)
                    .background(ChefitColors.pistachio)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    HStack {
                        Text("Popular Recipes")
                            .font(.custom("Nunito-Bold", size: 40))
                            .foregroundStyle(ChefitColors.text)
                        Spacer()
                        Text("See all")
                            .font(.custom("Nunito-Bold", size: 13))
                            .foregroundStyle(ChefitColors.sageGreen)
                    }
                    .padding(.top, 4)

                    HStack(spacing: 12) {
                        ForEach(ChefitSampleData.popularRecipes.prefix(2)) { recipe in
                            ChefitHomeRecipeCard(
                                title: recipe.title,
                                accentColor: recipe.id == "creamy-pasta" ? ChefitColors.honey : ChefitColors.matcha
                            ) {
                                onRecipeTap(recipe.id)
                            }
                            .frame(width: recipeCardWidth)
                        }
                    }
                }
                .padding(.horizontal, horizontalInset)
                .padding(.bottom, 20)
            }
            .background(ChefitColors.cream.ignoresSafeArea())
        }
    }
}

private struct ChefitHomeRecipeCard: View {
    let title: String
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ChefitColors.cream)
                    .frame(height: 130)
                    .overlay {
                        Circle()
                            .fill(ChefitColors.white)
                            .frame(width: 126, height: 82)
                            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 3)
                            .overlay(
                                Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                                    .font(.system(size: 54))
                                    .foregroundStyle(accentColor)
                            )
                    }

                Text(title.replacingOccurrences(of: " ", with: "\n"))
                    .font(.custom("Nunito-Bold", size: 14))
                    .foregroundStyle(ChefitColors.text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
            }
            .background(ChefitColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ChefitColors.text.opacity(0.12), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
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
