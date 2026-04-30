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
        .background(ChefitColors.cream.ignoresSafeArea())
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
                            Image(systemName: item.0)
                                .font(.system(size: 26, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(ChefitColors.sageGreen)
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
        }
        .background(ChefitColors.cream.ignoresSafeArea())
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
        }
        .background(ChefitColors.cream.ignoresSafeArea())
    }
}

struct ChefitShoppingListView: View {
    @EnvironmentObject private var cart: ShoppingCartViewModel
    @Environment(\.dismiss) private var dismiss

    var showDismissButton: Bool = false

    private var groupedSections: [(categoryRaw: String, items: [ShoppingItem])] {
        let dict = Dictionary(grouping: cart.items) { $0.category ?? "other" }
        return dict.keys.sorted {
            ShoppingListBuilder.categorySortIndex($0 == "other" ? nil : $0)
                < ShoppingListBuilder.categorySortIndex($1 == "other" ? nil : $1)
        }.map { raw in
            (
                raw,
                dict[raw]!.sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
            )
        }
    }

    private var hasUnchecked: Bool {
        cart.items.contains(where: { !$0.isChecked })
    }

    var body: some View {
        VStack(spacing: 0) {
            if cart.items.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(groupedSections, id: \.categoryRaw) { section in
                        Section {
                            ForEach(section.items) { item in
                                cartRow(item)
                                    .listRowBackground(ChefitColors.white)
                            }
                            .onDelete { offsets in
                                offsets.forEach { cart.removeItem(id: section.items[$0].id) }
                            }
                        } header: {
                            Text(ShoppingListBuilder.sectionTitle(for: section.categoryRaw == "other" ? nil : section.categoryRaw))
                                .font(ChefitTypography.label())
                                .foregroundStyle(ChefitColors.sageGreen)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .animation(.easeInOut(duration: 0.2), value: cart.items.map(\.isChecked))
            }

            if !cart.items.isEmpty, hasUnchecked {
                Button {
                    cart.openInstacart()
                } label: {
                    Label("Order with Instacart", systemImage: "cart.fill")
                }
                .buttonStyle(ChefitPrimaryButtonStyle())
                .padding(ChefitSpacing.md)
                .background(ChefitColors.cream.ignoresSafeArea(edges: .bottom))
            }
        }
        .background(ChefitColors.cream.ignoresSafeArea())
        .navigationTitle("Shopping List")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if showDismissButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(ChefitTypography.label())
                    .foregroundStyle(ChefitColors.sageGreen)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: ChefitSpacing.md) {
            Spacer()
            Image(systemName: "cart")
                .font(.system(size: 44))
                .foregroundStyle(ChefitColors.matcha)
            Text("Your cart is empty")
                .font(ChefitTypography.h3())
                .foregroundStyle(ChefitColors.sageGreen)
            Text("Open a recipe and add missing ingredients.")
                .font(ChefitTypography.body())
                .foregroundStyle(ChefitColors.matcha)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ChefitSpacing.lg)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func cartRow(_ item: ShoppingItem) -> some View {
        HStack(spacing: ChefitSpacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    cart.toggleItem(item)
                }
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(item.isChecked ? ChefitColors.matcha : ChefitColors.pistachio)
            }
            .buttonStyle(.plain)

            Text(item.name)
                .font(ChefitTypography.body())
                .foregroundStyle(item.isChecked ? ChefitColors.matcha : ChefitColors.sageGreen)
                .strikethrough(item.isChecked)

            Spacer(minLength: ChefitSpacing.sm)

            HStack(spacing: ChefitSpacing.sm) {
                quantityButton(icon: "minus.circle.fill") {
                    cart.updateQuantity(item, delta: -1)
                }
                Text("\(item.quantity)")
                    .font(ChefitTypography.label())
                    .foregroundStyle(ChefitColors.text)
                    .frame(minWidth: 22)
                quantityButton(icon: "plus.circle.fill") {
                    cart.updateQuantity(item, delta: 1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func quantityButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(ChefitColors.peach)
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
        }
        .background(ChefitColors.cream.ignoresSafeArea())
    }
}

struct ChefitProfileView: View {
    let onShoppingTap: () -> Void
    let onPantryTap: () -> Void
    let onLogout: () -> Void

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
                ChefitProfileMenuRow(label: "Sign Out", onTap: onLogout)
            }
            .padding(ChefitSpacing.md)
        }
        .background(ChefitColors.cream.ignoresSafeArea())
    }
}

struct ChefitCommunityView: View {
    @State private var feedTab = "For You"

    var body: some View {
        GeometryReader { proxy in
            let horizontalInset = max(14, proxy.size.width * 0.04)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(["For You", "Following", "Popular"], id: \.self) { tab in
                            Button {
                                feedTab = tab
                            } label: {
                                ZStack {
                                    if feedTab == tab {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(ChefitColors.peach.opacity(0.15))
                                    }
                                    Text(tab)
                                        .font(.custom("Nunito-Bold", size: 13))
                                        .foregroundStyle(feedTab == tab ? ChefitColors.text : ChefitColors.text.opacity(0.55))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 34)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                    Divider().overlay(ChefitColors.text.opacity(0.08))

                    VStack(spacing: 0) {
                        ForEach(Array(ChefitSampleData.communityPosts.prefix(2).enumerated()), id: \.offset) { index, post in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Circle()
                                        .fill(ChefitColors.honey.opacity(0.4))
                                        .frame(width: 24, height: 24)
                                        .overlay {
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(ChefitColors.text.opacity(0.75))
                                        }
                                    Text(post.user)
                                        .font(.custom("Nunito-SemiBold", size: 12))
                                        .foregroundStyle(ChefitColors.text)
                                    Text(post.time)
                                        .font(.custom("Nunito-Regular", size: 11))
                                        .foregroundStyle(ChefitColors.text.opacity(0.45))
                                    Spacer()
                                    Text("\(index + 2)h")
                                        .font(.custom("Nunito-Bold", size: 11))
                                        .foregroundStyle(ChefitColors.text.opacity(0.5))
                                }

                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(ChefitColors.cream)
                                    .frame(height: 150)
                                    .overlay {
                                        Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                                            .font(.system(size: 72))
                                            .foregroundStyle(ChefitColors.honey)
                                    }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Made Creamy Tomato Pasta")
                                        .font(.custom("Nunito-Bold", size: 16))
                                        .foregroundStyle(ChefitColors.text)
                                    Text("So easy and delicious!")
                                        .font(.custom("Nunito-SemiBold", size: 13))
                                        .foregroundStyle(ChefitColors.text)
                                    Text("#dinner  #quickmeals")
                                        .font(.custom("Nunito-SemiBold", size: 13))
                                        .foregroundStyle(ChefitColors.sageGreen)
                                }

                                HStack(spacing: 24) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "heart.fill")
                                            .foregroundStyle(ChefitColors.peach)
                                        Text("\(post.likes)")
                                    }
                                    HStack(spacing: 6) {
                                        Image(systemName: "bubble.left")
                                        Text("\(post.comments)")
                                    }
                                    Spacer()
                                    Image(systemName: "bookmark")
                                }
                                .font(.custom("Nunito-Bold", size: 14))
                                .foregroundStyle(ChefitColors.text.opacity(0.7))
                            }
                            .padding(12)
                            .overlay(alignment: .bottom) {
                                if index == 0 {
                                    Divider().overlay(ChefitColors.text.opacity(0.08))
                                }
                            }
                        }
                    }
                }
                .background(ChefitColors.white)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(ChefitColors.text.opacity(0.09), lineWidth: 1)
                }
                .padding(.horizontal, horizontalInset)
                .padding(.top, 10)
                .padding(.bottom, 10)

                Text("See what others cooked,\nget inspired and connect.")
                    .font(.custom("Nunito-SemiBold", size: 13))
                    .foregroundStyle(ChefitColors.text.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 20)
            }
            .background(ChefitColors.cream.ignoresSafeArea())
        }
    }
}
