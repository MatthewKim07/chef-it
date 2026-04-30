import SwiftUI
import PhotosUI
import ChefItKit

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

    @State private var selectedProviderId: String?

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

    private var providerQuotes: [ShoppingProviderQuote] {
        ShoppingProviderCatalog.quotes(for: cart.items)
    }

    private var recommendations: [SmartRecommendationCue] {
        ShoppingProviderCatalog.recommendations(for: cart.items)
    }

    var body: some View {
        Group {
            if cart.items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: ChefitSpacing.lg) {
                        BuyIngredientsSection(
                            quotes: providerQuotes,
                            recommendations: recommendations,
                            selectedProviderId: selectedProviderId,
                            onSelect: handleProviderSelect
                        )

                        IngredientList(
                            sections: groupedSections,
                            onToggle: { cart.toggleItem($0) },
                            onAdjust: { cart.updateQuantity($0, delta: $1) },
                            onRemove: { cart.removeItem(id: $0.id) }
                        )
                    }
                    .padding(.horizontal, ChefitSpacing.md)
                    .padding(.vertical, ChefitSpacing.md)
                }
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

    private func handleProviderSelect(_ provider: ShoppingProvider) {
        selectedProviderId = provider.id
        cart.open(provider: provider)
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
}

// MARK: - Buy Ingredients Section

private struct BuyIngredientsSection: View {
    let quotes: [ShoppingProviderQuote]
    let recommendations: [SmartRecommendationCue]
    let selectedProviderId: String?
    let onSelect: (ShoppingProvider) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Buy your ingredients")
                    .font(ChefitTypography.h3())
                    .foregroundStyle(ChefitColors.sageGreen)
                Text("Compare delivery, price, and availability across stores.")
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.matcha)
            }

            if !recommendations.isEmpty {
                SmartRecommendation(cues: recommendations)
                    .padding(.top, 2)
            }

            ProviderList(
                quotes: quotes,
                selectedProviderId: selectedProviderId,
                onSelect: onSelect
            )
        }
    }
}

// MARK: - Smart Recommendation

private struct SmartRecommendation: View {
    let cues: [SmartRecommendationCue]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ChefitSpacing.sm) {
                ForEach(cues) { cue in
                    HStack(spacing: 6) {
                        Image(systemName: iconName(for: cue.label))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(ChefitColors.sageGreen)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(cue.label)
                                .font(ChefitTypography.micro())
                                .foregroundStyle(ChefitColors.matcha)
                            Text(cue.detail)
                                .font(ChefitTypography.label())
                                .foregroundStyle(ChefitColors.sageGreen)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(ChefitColors.pistachio.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
                }
            }
        }
    }

    private func iconName(for label: String) -> String {
        if label.localizedCaseInsensitiveContains("price") { return "tag.fill" }
        if label.localizedCaseInsensitiveContains("coverage") { return "checklist" }
        return "bolt.fill"
    }
}

// MARK: - Provider List

private struct ProviderList: View {
    let quotes: [ShoppingProviderQuote]
    let selectedProviderId: String?
    let onSelect: (ShoppingProvider) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: ChefitSpacing.sm) {
                ForEach(quotes, id: \.provider.id) { quote in
                    ProviderCard(
                        quote: quote,
                        isSelected: quote.provider.id == selectedProviderId
                    ) {
                        onSelect(quote.provider)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Provider Card

private struct ProviderCard: View {
    let quote: ShoppingProviderQuote
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
                HStack(alignment: .center, spacing: ChefitSpacing.sm) {
                    ProviderLogo(provider: quote.provider)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(quote.provider.name)
                            .font(ChefitTypography.label())
                            .foregroundStyle(ChefitColors.text)
                        Text(quote.provider.deliveryEstimate)
                            .font(ChefitTypography.micro())
                            .foregroundStyle(ChefitColors.matcha)
                    }
                    Spacer(minLength: 0)
                }

                Text(quote.formattedTotal)
                    .font(.custom("Nunito-Bold", size: 22))
                    .foregroundStyle(ChefitColors.sageGreen)

                AvailabilityBadge(quote: quote)
            }
            .padding(ChefitSpacing.md)
            .frame(width: 196, alignment: .leading)
            .background(ChefitColors.white)
            .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous)
                    .stroke(
                        isSelected ? ChefitColors.peach : ChefitColors.text.opacity(0.07),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .chefitCardShadow()
        }
        .buttonStyle(.plain)
    }
}

private struct ProviderLogo: View {
    let provider: ShoppingProvider

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(provider.logoBackground)
            Image(systemName: provider.logoSymbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(provider.brandColor)
        }
        .frame(width: 36, height: 36)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(provider.brandColor.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct AvailabilityBadge: View {
    let quote: ShoppingProviderQuote

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: quote.hasAll ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(quote.hasAll ? ChefitColors.sageGreen : ChefitColors.peach)
            Text(quote.availabilityLabel)
                .font(ChefitTypography.micro())
                .fontWeight(.semibold)
                .foregroundStyle(quote.hasAll ? ChefitColors.sageGreen : ChefitColors.text.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(quote.hasAll ? ChefitColors.matcha.opacity(0.18) : ChefitColors.pistachio.opacity(0.55))
        .clipShape(Capsule(style: .continuous))
    }
}

// MARK: - Ingredient List

private struct IngredientList: View {
    let sections: [(categoryRaw: String, items: [ShoppingItem])]
    let onToggle: (ShoppingItem) -> Void
    let onAdjust: (ShoppingItem, Int) -> Void
    let onRemove: (ShoppingItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.md) {
            HStack {
                Text("Your list")
                    .font(ChefitTypography.h3())
                    .foregroundStyle(ChefitColors.sageGreen)
                Spacer()
                Text("\(sections.flatMap(\.items).filter { !$0.isChecked }.count) to buy")
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.matcha)
            }

            VStack(alignment: .leading, spacing: ChefitSpacing.md) {
                ForEach(sections, id: \.categoryRaw) { section in
                    VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
                        Text(ShoppingListBuilder.sectionTitle(for: section.categoryRaw == "other" ? nil : section.categoryRaw))
                            .font(ChefitTypography.micro())
                            .fontWeight(.semibold)
                            .foregroundStyle(ChefitColors.matcha)
                            .textCase(.uppercase)
                            .tracking(0.6)

                        VStack(spacing: 0) {
                            ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                                IngredientItem(
                                    item: item,
                                    onToggle: { onToggle(item) },
                                    onAdjust: { delta in onAdjust(item, delta) },
                                    onRemove: { onRemove(item) }
                                )
                                if index < section.items.count - 1 {
                                    Divider().overlay(ChefitColors.pistachio).padding(.leading, 44)
                                }
                            }
                        }
                        .padding(.vertical, ChefitSpacing.xs)
                        .padding(.horizontal, ChefitSpacing.sm)
                        .background(ChefitColors.white)
                        .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
                    }
                }
            }
        }
    }
}

private struct IngredientItem: View {
    let item: ShoppingItem
    let onToggle: () -> Void
    let onAdjust: (Int) -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: ChefitSpacing.sm) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { onToggle() } }) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(item.isChecked ? ChefitColors.matcha : ChefitColors.pistachio)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isChecked ? "Marked as already have" : "Mark as already have")

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(ChefitTypography.body())
                    .foregroundStyle(item.isChecked ? ChefitColors.matcha : ChefitColors.text)
                    .strikethrough(item.isChecked)
                if item.isChecked {
                    Text("Already in pantry")
                        .font(ChefitTypography.micro())
                        .foregroundStyle(ChefitColors.matcha)
                }
            }

            Spacer(minLength: ChefitSpacing.sm)

            QuantityStepper(value: item.quantity) { delta in
                if item.quantity + delta < 1 {
                    onRemove()
                } else {
                    onAdjust(delta)
                }
            }
            .opacity(item.isChecked ? 0.4 : 1)
            .disabled(item.isChecked)
        }
        .padding(.vertical, 10)
    }
}

private struct QuantityStepper: View {
    let value: Int
    let onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            stepperButton(systemName: "minus") { onChange(-1) }
            Text("\(value)")
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.text)
                .frame(minWidth: 22)
            stepperButton(systemName: "plus") { onChange(1) }
        }
        .padding(.horizontal, 4)
        .frame(height: 32)
        .background(ChefitColors.pistachio.opacity(0.5))
        .clipShape(Capsule(style: .continuous))
    }

    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(ChefitColors.sageGreen)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
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

// MARK: - Profile ViewModel

@MainActor
private final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var isUploadingAvatar = false
    @Published var errorMessage: String?
    @Published var showEditSheet = false
    @Published var editDisplayName = ""
    @Published var editBio = ""
    @Published var posts: [Post] = []
    @Published var isLoadingPosts = false

    func load(userId: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            profile = try await UserService.shared.fetchProfile(id: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func openEditSheet() {
        editDisplayName = profile?.displayName ?? ""
        editBio = profile?.bio ?? ""
        showEditSheet = true
    }

    func saveProfile(userId: Int) async {
        isSaving = true
        do {
            let name = editDisplayName.trimmingCharacters(in: .whitespaces)
            let bio  = editBio.trimmingCharacters(in: .whitespaces)
            profile = try await UserService.shared.updateProfile(
                id: userId,
                displayName: name.isEmpty ? nil : name,
                bio: bio.isEmpty ? nil : bio
            )
            showEditSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func uploadAvatar(userId: Int, imageData: Data) async {
        isUploadingAvatar = true
        do {
            let url = try await UserService.shared.uploadAvatar(id: userId, imageData: imageData)
            if let p = profile {
                profile = UserProfile(id: p.id, displayName: p.displayName,
                                      bio: p.bio, avatarURL: url, createdAt: p.createdAt)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isUploadingAvatar = false
    }

    func loadPosts(userId: Int) async {
        isLoadingPosts = true
        defer { isLoadingPosts = false }
        do { posts = try await PostService.shared.fetchPosts(userId: userId).posts } catch { }
    }

    func deletePost(id: Int) async {
        do {
            try await PostService.shared.deletePost(id: id)
            posts.removeAll { $0.id == id }
        } catch { }
    }
}

// MARK: - Profile View

struct ChefitProfileView: View {
    let onShoppingTap: () -> Void
    let onPantryTap: () -> Void
    let onLogout: () -> Void

    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var userProfileStore: CurrentUserProfileStore
    @StateObject private var vm = ProfileViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCreatePost = false
    @State private var selectedPost: Post?

    private var userId: Int? { authService.currentUser?.id }
    private var displayName: String {
        vm.profile?.displayName ?? authService.currentUser?.displayName ?? "Chef"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ChefitSpacing.lg) {
                profileHeaderCard
                if let msg = vm.errorMessage { errorBanner(msg) }
                postsSection
                menuCard
            }
            .padding(ChefitSpacing.md)
            .padding(.bottom, ChefitSpacing.twoXL)
        }
        .background(ChefitColors.cream.ignoresSafeArea())
        .task {
            if let id = userId {
                await vm.load(userId: id)
                await vm.loadPosts(userId: id)
            }
        }
        .onChange(of: vm.profile?.id) { _, _ in
            userProfileStore.update(vm.profile)
        }
        .onChange(of: vm.profile?.displayName) { _, _ in
            userProfileStore.update(vm.profile)
        }
        .onChange(of: vm.profile?.avatarURL) { _, _ in
            userProfileStore.update(vm.profile)
        }
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item, let id = userId else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await vm.uploadAvatar(userId: id, imageData: data)
                }
            }
        }
        .sheet(isPresented: $vm.showEditSheet) {
            if let id = userId {
                ProfileEditSheet(vm: vm, userId: id)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView { newPost in
                vm.posts.insert(newPost, at: 0)
            }
            .environmentObject(authService)
        }
        .sheet(item: $selectedPost) { post in
            PostDetailSheet(
                post: post,
                isOwnPost: post.userId == userId
            ) {
                await vm.deletePost(id: post.id)
            }
        }
    }

    // MARK: Header

    private var profileHeaderCard: some View {
        VStack(spacing: ChefitSpacing.sm) {
            // Avatar + camera overlay
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if vm.isUploadingAvatar {
                        Circle()
                            .fill(ChefitColors.pistachio)
                            .overlay { ProgressView().tint(ChefitColors.sageGreen) }
                    } else if let urlStr = vm.profile?.avatarURL, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().scaledToFill()
                            } else {
                                placeholderCircle
                            }
                        }
                        .clipShape(Circle())
                    } else {
                        placeholderCircle
                    }
                }
                .frame(width: 100, height: 100)
                .overlay(Circle().stroke(ChefitColors.cream, lineWidth: 3))

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(ChefitColors.peach)
                            .frame(width: 30, height: 30)
                        Image(systemName: "camera")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(ChefitColors.white)
                    }
                }
                .offset(x: 3, y: 3)
            }
            .padding(.top, ChefitSpacing.lg)

            // Name skeleton or real
            if vm.isLoading {
                RoundedRectangle(cornerRadius: 6)
                    .fill(ChefitColors.matcha.opacity(0.3))
                    .frame(width: 140, height: 26)
                RoundedRectangle(cornerRadius: 4)
                    .fill(ChefitColors.matcha.opacity(0.2))
                    .frame(width: 190, height: 15)
            } else {
                Text(displayName)
                    .font(ChefitTypography.h1())
                    .foregroundStyle(ChefitColors.sageGreen)
                    .multilineTextAlignment(.center)

                if let bio = vm.profile?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(ChefitTypography.body())
                        .foregroundStyle(ChefitColors.text.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ChefitSpacing.lg)
                } else {
                    Text("Add a bio to tell others about yourself")
                        .font(ChefitTypography.micro())
                        .foregroundStyle(ChefitColors.matcha)
                }
            }

            Button("Edit Profile") { vm.openEditSheet() }
                .buttonStyle(ChefitSecondaryButtonStyle())
                .frame(maxWidth: 180)
                .disabled(vm.isLoading)
                .padding(.top, ChefitSpacing.xs)
                .padding(.bottom, ChefitSpacing.lg)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [ChefitColors.pistachio, ChefitColors.matcha.opacity(0.28)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.lg, style: .continuous))
    }

    private var placeholderCircle: some View {
        Circle()
            .fill(ChefitColors.pistachio)
            .overlay {
                Image(systemName: "person")
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(ChefitColors.matcha)
            }
    }

    // MARK: Menu

    private var menuCard: some View {
        VStack(spacing: 0) {
            ChefitProfileMenuRow(label: "Shopping List", onTap: onShoppingTap)
            ChefitProfileMenuRow(label: "Pantry", onTap: onPantryTap)
            ChefitProfileMenuRow(label: "Settings", onTap: {})
            ChefitProfileMenuRow(label: "Help & Support", onTap: {})

            Button(action: onLogout) {
                HStack {
                    Text("Sign Out")
                        .font(ChefitTypography.body())
                        .foregroundStyle(ChefitColors.peach)
                    Spacer()
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(ChefitColors.peach.opacity(0.8))
                }
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ChefitSpacing.md)
        .background(ChefitColors.white)
        .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
        .chefitCardShadow()
    }

    // MARK: Posts Section

    private var postsSection: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
            HStack {
                Text("Posts")
                    .font(ChefitTypography.h2())
                    .foregroundStyle(ChefitColors.sageGreen)
                Spacer()
                Button {
                    showCreatePost = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ChefitColors.white)
                        .frame(width: 32, height: 32)
                        .background(ChefitColors.peach)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if vm.isLoadingPosts {
                HStack {
                    Spacer()
                    ProgressView().tint(ChefitColors.sageGreen)
                    Spacer()
                }
                .frame(height: 80)
            } else if vm.posts.isEmpty {
                VStack(spacing: ChefitSpacing.sm) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 32, weight: .thin))
                        .foregroundStyle(ChefitColors.matcha)
                    Text("No posts yet")
                        .font(ChefitTypography.body())
                        .foregroundStyle(ChefitColors.matcha)
                    Text("Tap + to share your first dish!")
                        .font(ChefitTypography.micro())
                        .foregroundStyle(ChefitColors.matcha.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ChefitSpacing.twoXL)
            } else {
                let columns = [
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2)
                ]
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(vm.posts) { post in
                        PostThumbnailCell(post: post) {
                            selectedPost = post
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
            }
        }
    }

    // MARK: Error banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: ChefitSpacing.sm) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(ChefitColors.peach)
            Text(message)
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.sageGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button { vm.errorMessage = nil } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(ChefitColors.matcha)
            }
        }
        .padding(ChefitSpacing.md)
        .background(ChefitColors.peach.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.sm, style: .continuous))
    }
}

// MARK: - Post Thumbnail Cell

private struct PostThumbnailCell: View {
    let post: Post
    let onTap: () -> Void

    var body: some View {
        GeometryReader { geo in
            Button(action: onTap) {
                Group {
                    if let urlStr = post.imageURL, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().scaledToFill()
                            } else {
                                thumbnailPlaceholder
                            }
                        }
                    } else {
                        thumbnailPlaceholder
                    }
                }
                .frame(width: geo.size.width, height: geo.size.width)
                .clipped()
            }
            .buttonStyle(.plain)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var thumbnailPlaceholder: some View {
        Rectangle()
            .fill(ChefitColors.pistachio)
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.system(size: 18, weight: .thin))
                    .foregroundStyle(ChefitColors.matcha)
            }
    }
}

// MARK: - Edit Sheet

private struct ProfileEditSheet: View {
    @ObservedObject var vm: ProfileViewModel
    let userId: Int
    @FocusState private var focused: EditField?

    private enum EditField { case name, bio }

    var body: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.md) {
            HStack {
                Text("Edit Profile")
                    .font(ChefitTypography.h2())
                    .foregroundStyle(ChefitColors.sageGreen)
                Spacer()
                Button { vm.showEditSheet = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(ChefitColors.matcha)
                }
            }

            fieldLabel("Display Name")
            TextField("Your name", text: $vm.editDisplayName)
                .font(ChefitTypography.body())
                .foregroundStyle(ChefitColors.text)
                .focused($focused, equals: .name)
                .profileTextField(isFocused: focused == .name)

            fieldLabel("Bio")
            TextEditor(text: $vm.editBio)
                .font(ChefitTypography.body())
                .foregroundStyle(ChefitColors.text)
                .focused($focused, equals: .bio)
                .frame(height: 84)
                .scrollContentBackground(.hidden)
                .padding(ChefitSpacing.sm)
                .background(ChefitColors.pistachio.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.sm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: ChefitRadius.sm, style: .continuous)
                        .stroke(focused == .bio ? ChefitColors.sageGreen : ChefitColors.matcha,
                                lineWidth: focused == .bio ? 1.5 : 1)
                )

            if let msg = vm.errorMessage {
                Text(msg)
                    .font(ChefitTypography.label())
                    .foregroundStyle(ChefitColors.peach)
            }

            Spacer()

            Button {
                Task { await vm.saveProfile(userId: userId) }
            } label: {
                if vm.isSaving {
                    HStack(spacing: ChefitSpacing.sm) {
                        ProgressView().tint(ChefitColors.white)
                        Text("Saving…")
                    }
                } else {
                    Text("Save Changes")
                }
            }
            .buttonStyle(ChefitPrimaryButtonStyle())
            .disabled(vm.isSaving)
        }
        .padding(ChefitSpacing.md)
        .background(ChefitColors.cream.ignoresSafeArea())
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(ChefitTypography.label())
            .foregroundStyle(ChefitColors.sageGreen)
    }
}

private extension View {
    func profileTextField(isFocused: Bool) -> some View {
        self
            .padding(.horizontal, ChefitSpacing.md)
            .padding(.vertical, 12)
            .background(ChefitColors.pistachio.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ChefitRadius.sm, style: .continuous)
                    .stroke(isFocused ? ChefitColors.sageGreen : ChefitColors.matcha,
                            lineWidth: isFocused ? 1.5 : 1)
            )
    }
}

struct ChefitCommunityView: View {
    let onAuthorTap: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Community")
                    .font(ChefitTypography.h2())
                    .foregroundStyle(ChefitColors.sageGreen)
                Spacer()
            }
            .padding(.horizontal, ChefitSpacing.md)
            .padding(.top, ChefitSpacing.md)
            .padding(.bottom, ChefitSpacing.sm)

            Divider()
                .overlay(ChefitColors.pistachio.opacity(0.8))

            FeedView(onAuthorTap: onAuthorTap)
        }
        .background(ChefitColors.cream.ignoresSafeArea())
    }
}
