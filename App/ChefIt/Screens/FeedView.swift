import SwiftUI
import ChefItKit

// MARK: - ViewModel

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: String?

    private var total = 0
    private let pageSize = 20

    var hasMore: Bool {
        PostService.shared.hasMorePosts(loadedCount: posts.count, totalCount: total)
    }

    func loadInitial() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        do {
            let page = try await PostService.shared.fetchPosts(limit: pageSize, offset: 0)
            posts = page.posts
            total = page.total
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore, !isLoading else { return }
        isLoadingMore = true
        do {
            let page = try await PostService.shared.fetchPosts(limit: pageSize, offset: posts.count)
            posts.append(contentsOf: page.posts)
            total = page.total
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingMore = false
    }

    func refresh() async {
        total = 0
        posts = []
        await loadInitial()
    }

    func deletePost(id: Int) async {
        do {
            try await PostService.shared.deletePost(id: id)
            posts.removeAll { $0.id == id }
            total = max(0, total - 1)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updatePost(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index] = post
    }

    func toggleLike(postId: Int) async {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        let original = posts[index]
        let optimistic = original.updatingLike(
            count: original.likedByMe ? max(0, original.likeCount - 1) : original.likeCount + 1,
            liked: !original.likedByMe
        )
        posts[index] = optimistic

        do {
            let result = original.likedByMe
                ? try await PostService.shared.unlikePost(id: postId)
                : try await PostService.shared.likePost(id: postId)
            if let i = posts.firstIndex(where: { $0.id == postId }) {
                posts[i] = posts[i].updatingLike(count: result.likeCount, liked: result.liked)
            }
        } catch {
            if let i = posts.firstIndex(where: { $0.id == postId }) {
                posts[i] = original
            }
            self.error = error.localizedDescription
        }
    }
}

// MARK: - FeedView

struct FeedView: View {
    let onAuthorTap: (Int) -> Void

    @EnvironmentObject private var authService: AuthService
    @StateObject private var vm = FeedViewModel()

    @State private var selectedPost: Post?

    private var currentUserId: Int? { authService.currentUser?.id }

    var body: some View {
        ZStack {
            if vm.isLoading && vm.posts.isEmpty {
                loadingState
            } else if let error = vm.error, vm.posts.isEmpty {
                errorState(error)
            } else if vm.posts.isEmpty {
                emptyState
            } else {
                feedList
            }
        }
        .background(ChefitColors.cream.ignoresSafeArea())
        .task { await vm.loadInitial() }
        .fullScreenCover(item: $selectedPost) { post in
            PostDetailFullScreenView(
                post: post,
                currentUserId: currentUserId,
                onBack: { selectedPost = nil },
                onPostUpdated: { updatedPost in
                    selectedPost = updatedPost
                    vm.updatePost(updatedPost)
                },
                onDelete: { p in await vm.deletePost(id: p.id) }
            )
            .environmentObject(authService)
        }
    }

    private var feedList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: ChefitSpacing.md) {
                ForEach(vm.posts) { post in
                    PostCardView(
                        post: post,
                        currentUserId: currentUserId,
                        onAuthorTap: onAuthorTap,
                        onImageTap: { tappedPost in
                            selectedPost = tappedPost
                        },
                        onCommentTap: { tappedPost in
                            selectedPost = tappedPost
                        },
                        onLikeTap: { tappedPost in
                            Task { await vm.toggleLike(postId: tappedPost.id) }
                        },
                        onDelete: { tappedPost in await vm.deletePost(id: tappedPost.id) }
                    )
                    .onAppear {
                        if post.id == vm.posts.last?.id {
                            Task { await vm.loadMore() }
                        }
                    }
                }

                if vm.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(ChefitColors.matcha)
                            .padding(.vertical, ChefitSpacing.lg)
                        Spacer()
                    }
                } else if !vm.hasMore && !vm.posts.isEmpty {
                    Text("You're all caught up, Chef.")
                        .font(ChefitTypography.micro())
                        .foregroundStyle(ChefitColors.matcha)
                        .padding(.vertical, ChefitSpacing.lg)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, ChefitSpacing.md)
            .padding(.top, ChefitSpacing.sm)
            .padding(.bottom, ChefitSpacing.twoXL)
        }
        .refreshable { await vm.refresh() }
    }

    private var loadingState: some View {
        VStack(spacing: ChefitSpacing.md) {
            ProgressView()
                .tint(ChefitColors.sageGreen)
                .scaleEffect(1.3)

            Text("Loading the latest dishes from the community...")
                .font(ChefitTypography.body())
                .foregroundStyle(ChefitColors.matcha)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: ChefitSpacing.lg) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(ChefitColors.matcha)

            VStack(spacing: ChefitSpacing.sm) {
                Text("No posts yet")
                    .font(ChefitTypography.h2())
                    .foregroundStyle(ChefitColors.sageGreen)

                Text("Be the first Chef to share something!")
                    .font(ChefitTypography.body())
                    .foregroundStyle(ChefitColors.matcha)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(ChefitSpacing.twoXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: ChefitSpacing.lg) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(ChefitColors.peach)

            VStack(spacing: ChefitSpacing.sm) {
                Text("Hmm, we couldn't load the feed")
                    .font(ChefitTypography.h3())
                    .foregroundStyle(ChefitColors.sageGreen)

                Text(message)
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.matcha)
                    .multilineTextAlignment(.center)
            }

            Button("Try again") {
                Task { await vm.loadInitial() }
            }
            .buttonStyle(ChefitSecondaryButtonStyle())
            .frame(maxWidth: 200)
        }
        .padding(ChefitSpacing.twoXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
