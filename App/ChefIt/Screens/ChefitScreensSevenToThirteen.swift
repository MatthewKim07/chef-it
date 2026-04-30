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
            .background(ChefitColors.cream.ignoresSafeArea())
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
        .background(ChefitColors.cream.ignoresSafeArea())
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
}

// MARK: - Profile View

struct ChefitProfileView: View {
    let onShoppingTap: () -> Void
    let onPantryTap: () -> Void
    let onLogout: () -> Void

    @EnvironmentObject private var authService: AuthService
    @StateObject private var vm = ProfileViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?

    private var userId: Int? { authService.currentUser?.id }
    private var displayName: String {
        vm.profile?.displayName ?? authService.currentUser?.displayName ?? "Chef"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ChefitSpacing.lg) {
                profileHeaderCard
                if let msg = vm.errorMessage { errorBanner(msg) }
                menuCard
            }
            .padding(ChefitSpacing.md)
            .padding(.bottom, ChefitSpacing.twoXL)
        }
        .background(ChefitColors.cream.ignoresSafeArea())
        .task {
            if let id = userId { await vm.load(userId: id) }
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
