import SwiftUI

struct ChefitScanPantryView: View {
    let onScanNow: () -> Void
    let onAddManually: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.lg) {
            Text("chefit")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.sageGreen)

            VStack(spacing: ChefitSpacing.sm) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 42))
                    .foregroundStyle(ChefitColors.matcha)
                Text("We'll find recipes you can make!")
                    .font(ChefitTypography.body())
                    .foregroundStyle(ChefitColors.sageGreen)
            }
            .frame(maxWidth: .infinity, minHeight: 340)
            .overlay(
                RoundedRectangle(cornerRadius: ChefitRadius.lg, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                    .foregroundStyle(ChefitColors.sageGreen)
            )

            Button {
                onScanNow()
            } label: {
                Label("Scan Now", systemImage: "camera")
            }
            .buttonStyle(ChefitPrimaryButtonStyle())

            Button("Add Manually", action: onAddManually)
                .buttonStyle(ChefitSecondaryButtonStyle())

            Spacer()
        }
        .padding(ChefitSpacing.md)
        .background(ChefitColors.cream)
    }
}

struct ChefitDetectedIngredientsView: View {
    let onFindRecipes: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ChefitSpacing.md) {
                HStack {
                    Text("Detected Ingredients")
                        .font(ChefitTypography.h2())
                        .foregroundStyle(ChefitColors.sageGreen)
                    Spacer()
                    Text("Edit")
                        .font(ChefitTypography.label())
                        .foregroundStyle(ChefitColors.peach)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: ChefitSpacing.md) {
                    ForEach(ChefitSampleData.detectedIngredients, id: \.1) { item in
                        VStack(spacing: ChefitSpacing.xs) {
                            Text(item.0)
                                .font(.system(size: 30))
                                .frame(width: 60, height: 60)
                                .background(ChefitColors.pistachio)
                                .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
                            Text(item.1)
                                .font(ChefitTypography.micro())
                                .foregroundStyle(ChefitColors.sageGreen)
                        }
                    }
                }

                Button("Find Recipes", action: onFindRecipes)
                    .buttonStyle(ChefitPrimaryButtonStyle())
                    .padding(.top, ChefitSpacing.md)
            }
            .padding(ChefitSpacing.md)
            .padding(.bottom, 90)
        }
        .background(ChefitColors.cream)
    }
}

struct ChefitRecommendationsView: View {
    let onRecipeTap: (String) -> Void
    @State private var favorites: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ChefitSpacing.md) {
                Text("Recipes you can make")
                    .font(ChefitTypography.h2())
                    .foregroundStyle(ChefitColors.sageGreen)
                Text("Based on your ingredients")
                    .font(ChefitTypography.label())
                    .foregroundStyle(ChefitColors.matcha)

                VStack(spacing: ChefitSpacing.md) {
                    ForEach(ChefitSampleData.popularRecipes) { recipe in
                        HStack(spacing: ChefitSpacing.sm) {
                            AsyncImage(url: recipe.imageURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                RoundedRectangle(cornerRadius: ChefitRadius.md).fill(ChefitColors.pistachio)
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.sm, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.title)
                                    .font(ChefitTypography.h3())
                                    .foregroundStyle(ChefitColors.sageGreen)
                                Text("\(recipe.minutes) min · \(recipe.difficulty)")
                                    .font(ChefitTypography.micro())
                                    .foregroundStyle(ChefitColors.matcha)
                            }
                            Spacer()
                            Button {
                                if favorites.contains(recipe.id) { favorites.remove(recipe.id) }
                                else { favorites.insert(recipe.id) }
                            } label: {
                                Image(systemName: favorites.contains(recipe.id) ? "heart.fill" : "heart")
                                    .foregroundStyle(favorites.contains(recipe.id) ? ChefitColors.peach : ChefitColors.matcha)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(ChefitSpacing.sm)
                        .background(ChefitColors.white)
                        .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
                        .chefitCardShadow()
                        .onTapGesture {
                            onRecipeTap(recipe.id)
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

struct ChefitShoppingListView: View {
    @State private var checkedToBuy: Set<String> = []
    @State private var showToast = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: ChefitSpacing.md) {
                    HStack {
                        Text("Shopping List")
                            .font(ChefitTypography.h2())
                            .foregroundStyle(ChefitColors.sageGreen)
                        Spacer()
                        Text("Edit")
                            .font(ChefitTypography.label())
                            .foregroundStyle(ChefitColors.peach)
                    }

                    section("To Buy")
                    ForEach(ChefitSampleData.shoppingToBuy, id: \.self) { item in
                        checkRow(item: item, isChecked: checkedToBuy.contains(item)) {
                            if checkedToBuy.contains(item) { checkedToBuy.remove(item) }
                            else { checkedToBuy.insert(item) }
                        }
                    }

                    section("Pantry")
                    ForEach(ChefitSampleData.shoppingPantry, id: \.self) { item in
                        checkRow(item: item, isChecked: true) {}
                    }
                }
                .padding(ChefitSpacing.md)
                .padding(.bottom, 90)
            }

            Button {
                showToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    showToast = false
                }
            } label: {
                Label("Add All to Cart", systemImage: "bag")
            }
            .buttonStyle(ChefitPrimaryButtonStyle())
            .padding(ChefitSpacing.md)
            .background(ChefitColors.cream)
            .overlay(alignment: .top) {
                if showToast {
                    Text("Added to cart!")
                        .font(ChefitTypography.label())
                        .foregroundStyle(ChefitColors.white)
                        .padding(.horizontal, ChefitSpacing.md)
                        .padding(.vertical, ChefitSpacing.sm)
                        .background(ChefitColors.sageGreen)
                        .clipShape(Capsule())
                        .padding(.top, -46)
                }
            }
        }
        .background(ChefitColors.cream)
    }

    private func section(_ title: String) -> some View {
        Text(title)
            .font(ChefitTypography.label())
            .foregroundStyle(ChefitColors.sageGreen)
    }

    private func checkRow(item: String, isChecked: Bool, tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            HStack {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isChecked ? ChefitColors.matcha : ChefitColors.pistachio)
                Text(item)
                    .font(ChefitTypography.body())
                    .foregroundStyle(isChecked ? ChefitColors.matcha : ChefitColors.sageGreen)
                    .strikethrough(isChecked)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

struct ChefitSavedView: View {
    let onRecipeTap: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ChefitSpacing.md) {
                HStack {
                    Text("Saved Recipes")
                        .font(ChefitTypography.h2())
                        .foregroundStyle(ChefitColors.sageGreen)
                    Spacer()
                    Text("Edit")
                        .font(ChefitTypography.label())
                        .foregroundStyle(ChefitColors.peach)
                }

                ForEach(ChefitSampleData.popularRecipes) { recipe in
                    HStack(spacing: ChefitSpacing.sm) {
                        AsyncImage(url: recipe.imageURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: ChefitRadius.md).fill(ChefitColors.pistachio)
                        }
                        .frame(width: 90, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.title)
                                .font(ChefitTypography.h3())
                                .foregroundStyle(ChefitColors.sageGreen)
                            Text("\(recipe.minutes) min · \(recipe.difficulty)")
                                .font(ChefitTypography.micro())
                                .foregroundStyle(ChefitColors.matcha)
                        }
                        Spacer()
                        Image(systemName: "heart.fill")
                            .foregroundStyle(ChefitColors.peach)
                    }
                    .padding(ChefitSpacing.sm)
                    .background(ChefitColors.white)
                    .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
                    .chefitCardShadow()
                    .onTapGesture {
                        onRecipeTap(recipe.id)
                    }
                }
            }
            .padding(ChefitSpacing.md)
            .padding(.bottom, 90)
        }
        .background(ChefitColors.cream)
    }
}

struct ChefitProfileView: View {
    let onShoppingTap: () -> Void
    let onPantryTap: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ChefitSpacing.md) {
                HStack(spacing: ChefitSpacing.md) {
                    Circle()
                        .fill(ChefitColors.pistachio)
                        .frame(width: 72, height: 72)
                        .overlay(Image(systemName: "person.fill").foregroundStyle(ChefitColors.sageGreen))
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("Chef")
                                .font(ChefitTypography.h2())
                                .foregroundStyle(ChefitColors.sageGreen)
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(ChefitColors.matcha)
                        }
                        Text("View Profile")
                            .font(ChefitTypography.label())
                            .foregroundStyle(ChefitColors.peach)
                    }
                }

                ChefitProfileMenuRow(label: "My Recipes", onTap: {})
                ChefitProfileMenuRow(label: "Cooking Stats", onTap: {})
                ChefitProfileMenuRow(label: "Shopping List", onTap: onShoppingTap)
                ChefitProfileMenuRow(label: "Pantry", onTap: onPantryTap)
                ChefitProfileMenuRow(label: "Settings", onTap: {})
                ChefitProfileMenuRow(label: "Help & Support", onTap: {})
            }
            .padding(ChefitSpacing.md)
            .padding(.bottom, 90)
        }
        .background(ChefitColors.cream)
    }
}

struct ChefitCommunityView: View {
    @State private var feedTab = "For You"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ChefitSpacing.md) {
                HStack(spacing: ChefitSpacing.md) {
                    ForEach(["For You", "Following", "Popular"], id: \.self) { tab in
                        Button {
                            feedTab = tab
                        } label: {
                            VStack(spacing: 4) {
                                Text(tab)
                                    .font(ChefitTypography.label())
                                    .foregroundStyle(feedTab == tab ? ChefitColors.sageGreen : ChefitColors.matcha)
                                Rectangle()
                                    .fill(feedTab == tab ? ChefitColors.peach : .clear)
                                    .frame(height: 2)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                ForEach(Array(ChefitSampleData.communityPosts.enumerated()), id: \.offset) { _, post in
                    VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
                        HStack {
                            Circle()
                                .fill(ChefitColors.pistachio)
                                .frame(width: 40, height: 40)
                            VStack(alignment: .leading) {
                                Text(post.user)
                                    .font(ChefitTypography.label())
                                    .foregroundStyle(ChefitColors.sageGreen)
                                Text(post.time)
                                    .font(ChefitTypography.micro())
                                    .foregroundStyle(ChefitColors.matcha)
                            }
                            Spacer()
                        }

                        AsyncImage(url: post.imageURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: ChefitRadius.md).fill(ChefitColors.pistachio)
                        }
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))

                        Text(post.caption)
                            .font(ChefitTypography.body())
                            .foregroundStyle(ChefitColors.sageGreen)

                        HStack(spacing: ChefitSpacing.md) {
                            Text("❤️ \(post.likes)")
                            Text("💬 \(post.comments)")
                            Text("🔖")
                        }
                        .font(ChefitTypography.label())
                        .foregroundStyle(ChefitColors.matcha)
                    }
                    .padding(ChefitSpacing.md)
                    .background(ChefitColors.white)
                    .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
                    .chefitCardShadow()
                }
            }
            .padding(ChefitSpacing.md)
            .padding(.bottom, 90)
        }
        .background(ChefitColors.cream)
    }
}
