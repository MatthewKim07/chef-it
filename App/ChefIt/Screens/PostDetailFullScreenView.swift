import SwiftUI
import ChefItKit

@MainActor
private final class PostDetailViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoadingComments = false
    @Published var isSubmittingComment = false
    @Published var errorMessage: String?

    func loadComments(postId: Int) async {
        guard !isLoadingComments else { return }
        isLoadingComments = true
        errorMessage = nil
        do {
            comments = try await CommentService.shared.fetchComments(postId: postId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingComments = false
    }

    func createComment(postId: Int, body: String) async throws -> Comment {
        isSubmittingComment = true
        defer { isSubmittingComment = false }

        let comment = try await CommentService.shared.createComment(postId: postId, body: body)
        comments.append(comment)
        return comment
    }
}

struct PostDetailFullScreenView: View {
    let post: Post
    let currentUserId: Int?
    let onBack: () -> Void
    let onPostUpdated: (Post) -> Void
    let onDelete: ((Post) async -> Void)?

    @StateObject private var vm = PostDetailViewModel()
    @State private var activePost: Post
    @State private var commentBody = ""
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var showReviewComposer = false
    @FocusState private var isCommentFieldFocused: Bool

    init(
        post: Post,
        currentUserId: Int?,
        onBack: @escaping () -> Void,
        onPostUpdated: @escaping (Post) -> Void,
        onDelete: ((Post) async -> Void)?
    ) {
        self.post = post
        self.currentUserId = currentUserId
        self.onBack = onBack
        self.onPostUpdated = onPostUpdated
        self.onDelete = onDelete
        _activePost = State(initialValue: post)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Color.clear.frame(height: 56)

                        postImage

                        VStack(alignment: .leading, spacing: ChefitSpacing.md) {
                            authorRow

                            if let caption = activePost.caption, !caption.isEmpty {
                                Text(caption)
                                    .font(ChefitTypography.body())
                                    .foregroundStyle(ChefitColors.text)
                            }

                            commentSummary

                            if let recipeId = activePost.recipeId, !recipeId.isEmpty {
                                reviewCallout(recipeId: recipeId)
                            }

                            commentsSection

                            if activePost.userId == currentUserId {
                                deleteButton
                            }
                        }
                        .padding(ChefitSpacing.md)

                        Color.clear.frame(height: ChefitSpacing.xl)
                    }
                }

                composerBar
            }
            .background(ChefitColors.cream.ignoresSafeArea())

            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ChefitColors.sageGreen)
                    .frame(width: 38, height: 38)
                    .background(ChefitColors.white.opacity(0.92))
                    .clipShape(Circle())
                    .chefitCardShadow()
            }
            .buttonStyle(.plain)
            .padding(.leading, ChefitSpacing.md)
            .padding(.top, ChefitSpacing.md)
        }
        .task { await vm.loadComments(postId: activePost.id) }
        .background(ChefitColors.cream.ignoresSafeArea())
        .confirmationDialog("Delete this post?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    isDeleting = true
                    await onDelete?(activePost)
                    isDeleting = false
                    onBack()
                }
            }
        } message: {
            Text("This can't be undone.")
        }
        .sheet(isPresented: $showReviewComposer) {
            if let recipeId = activePost.recipeId {
                ReviewComposerSheet(
                    recipeId: recipeId,
                    currentUserId: currentUserId
                ) { _ in }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var postImage: some View {
        Group {
            if let urlStr = activePost.imageURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        imagePlaceholder
                    default:
                        ZStack {
                            imagePlaceholder
                            ProgressView().tint(ChefitColors.matcha)
                        }
                    }
                }
            } else {
                imagePlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .background(ChefitColors.pistachio.opacity(0.25))
    }

    private var authorRow: some View {
        HStack(spacing: ChefitSpacing.sm) {
            avatarView

            VStack(alignment: .leading, spacing: 2) {
                Text(activePost.displayName ?? "Chef")
                    .font(ChefitTypography.label())
                    .foregroundStyle(ChefitColors.sageGreen)

                Text(RelativePostDateFormatter.string(from: activePost.createdAt))
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.matcha)
            }

            Spacer()
        }
    }

    private var commentSummary: some View {
        HStack(spacing: ChefitSpacing.lg) {
            Button {
                Task { await toggleLike() }
            } label: {
                HStack(spacing: ChefitSpacing.xs) {
                    Image(systemName: activePost.likedByMe ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .regular))
                    Text("\(activePost.likeCount) likes")
                        .font(ChefitTypography.label())
                }
                .foregroundStyle(activePost.likedByMe ? ChefitColors.peach : ChefitColors.sageGreen.opacity(0.82))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(activePost.likedByMe ? "Unlike" : "Like")

            HStack(spacing: ChefitSpacing.xs) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 14, weight: .regular))
                Text("\(activePost.commentCount) comments")
                    .font(ChefitTypography.label())
            }
            .foregroundStyle(ChefitColors.sageGreen.opacity(0.82))
        }
    }

    private func toggleLike() async {
        let original = activePost
        activePost = original.updatingLike(
            count: original.likedByMe ? max(0, original.likeCount - 1) : original.likeCount + 1,
            liked: !original.likedByMe
        )
        onPostUpdated(activePost)

        do {
            let result = original.likedByMe
                ? try await PostService.shared.unlikePost(id: original.id)
                : try await PostService.shared.likePost(id: original.id)
            activePost = activePost.updatingLike(count: result.likeCount, liked: result.liked)
            onPostUpdated(activePost)
        } catch {
            activePost = original
            onPostUpdated(activePost)
        }
    }

    private func reviewCallout(recipeId: String) -> some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
            HStack {
                Label("Recipe linked", systemImage: "fork.knife.circle")
                    .font(ChefitTypography.label())
                    .foregroundStyle(ChefitColors.sageGreen)
                Spacer()
                Button("Rate this recipe") {
                    showReviewComposer = true
                }
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.peach)
                .buttonStyle(.plain)
            }

            Text(recipeId)
                .font(ChefitTypography.micro())
                .foregroundStyle(ChefitColors.matcha)
                .lineLimit(1)
        }
        .padding(ChefitSpacing.md)
        .background(ChefitColors.white)
        .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
        .chefitCardShadow()
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
            Divider()
                .overlay(ChefitColors.pistachio)

            Text("Comments")
                .font(ChefitTypography.h3())
                .foregroundStyle(ChefitColors.sageGreen)

            if vm.isLoadingComments {
                HStack {
                    Spacer()
                    ProgressView().tint(ChefitColors.sageGreen)
                    Spacer()
                }
                .padding(.vertical, ChefitSpacing.xl)
            } else if let errorMessage = vm.errorMessage {
                Text(errorMessage)
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.peach)
            } else if vm.comments.isEmpty {
                VStack(spacing: ChefitSpacing.sm) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 30, weight: .thin))
                        .foregroundStyle(ChefitColors.matcha)

                    Text("No comments yet")
                        .font(ChefitTypography.h3())
                        .foregroundStyle(ChefitColors.sageGreen)

                    Text("Start the conversation, Chef.")
                        .font(ChefitTypography.body())
                        .foregroundStyle(ChefitColors.matcha)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ChefitSpacing.xl)
            } else {
                LazyVStack(spacing: ChefitSpacing.md) {
                    ForEach(vm.comments) { comment in
                        CommentRowView(comment: comment)
                    }
                }
            }
        }
    }

    private var composerBar: some View {
        VStack(spacing: ChefitSpacing.sm) {
            if let errorMessage = vm.errorMessage, !vm.isLoadingComments {
                Text(errorMessage)
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.peach)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(alignment: .bottom, spacing: ChefitSpacing.sm) {
                ZStack(alignment: .topLeading) {
                    if commentBody.isEmpty {
                        Text("Share a comment...")
                            .font(ChefitTypography.body())
                            .foregroundStyle(ChefitColors.matcha)
                            .padding(.horizontal, ChefitSpacing.md)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $commentBody)
                        .font(ChefitTypography.body())
                        .foregroundStyle(ChefitColors.text)
                        .focused($isCommentFieldFocused)
                        .frame(minHeight: 48, maxHeight: 96)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, ChefitSpacing.sm)
                        .padding(.vertical, ChefitSpacing.xs)
                        .background(Color.clear)
                }
                .background(ChefitColors.white)
                .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.xl, style: .continuous))

                Button {
                    Task { await submitComment() }
                } label: {
                    if vm.isSubmittingComment {
                        ProgressView().tint(ChefitColors.white)
                            .frame(width: 48, height: 48)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(ChefitColors.white)
                            .frame(width: 48, height: 48)
                    }
                }
                .buttonStyle(.plain)
                .background(ChefitColors.peach)
                .clipShape(Circle())
                .disabled(commentBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSubmittingComment)
                .opacity(commentBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSubmittingComment ? 0.6 : 1)
            }
        }
        .padding(.horizontal, ChefitSpacing.md)
        .padding(.top, ChefitSpacing.sm)
        .padding(.bottom, ChefitSpacing.md)
        .background(ChefitColors.cream.ignoresSafeArea())
    }

    private var deleteButton: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            if isDeleting {
                HStack(spacing: ChefitSpacing.sm) {
                    ProgressView().tint(ChefitColors.peach)
                    Text("Deleting...")
                }
            } else {
                Label("Delete Post", systemImage: "trash")
            }
        }
        .font(ChefitTypography.button())
        .foregroundStyle(ChefitColors.peach)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 48)
        .overlay(
            RoundedRectangle(cornerRadius: ChefitRadius.xl, style: .continuous)
                .stroke(ChefitColors.peach, lineWidth: 1.5)
        )
        .disabled(isDeleting)
        .padding(.top, ChefitSpacing.sm)
    }

    private var avatarView: some View {
        Group {
            if let urlStr = activePost.avatarURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .overlay(Circle().stroke(ChefitColors.pistachio, lineWidth: 2))
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(ChefitColors.pistachio)
            .frame(height: 320)
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundStyle(ChefitColors.matcha)
            }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(ChefitColors.pistachio)
            .overlay {
                Image(systemName: "person")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(ChefitColors.matcha)
            }
    }

    private func submitComment() async {
        let trimmed = commentBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            _ = try await vm.createComment(postId: activePost.id, body: trimmed)
            commentBody = ""
            isCommentFieldFocused = false
            activePost = activePost.updatingCommentCount(activePost.commentCount + 1)
            onPostUpdated(activePost)
        } catch {
            vm.errorMessage = error.localizedDescription
        }
    }
}

private struct CommentRowView: View {
    let comment: Comment

    var body: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
            HStack(spacing: ChefitSpacing.sm) {
                avatarView

                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.displayName ?? "Chef")
                        .font(ChefitTypography.label())
                        .foregroundStyle(ChefitColors.sageGreen)

                    Text(RelativePostDateFormatter.string(from: comment.createdAt))
                        .font(ChefitTypography.micro())
                        .foregroundStyle(ChefitColors.matcha)
                }

                Spacer()
            }

            Text(comment.body)
                .font(ChefitTypography.body())
                .foregroundStyle(ChefitColors.text)
        }
        .padding(ChefitSpacing.md)
        .background(ChefitColors.white)
        .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
        .chefitCardShadow()
    }

    private var avatarView: some View {
        Group {
            if let urlStr = comment.avatarURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: 38, height: 38)
        .clipShape(Circle())
        .overlay(Circle().stroke(ChefitColors.pistachio, lineWidth: 2))
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(ChefitColors.pistachio)
            .overlay {
                Image(systemName: "person")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(ChefitColors.matcha)
            }
    }
}

enum RelativePostDateFormatter {
    static func string(from iso8601: String) -> String {
        let formatters = makeFormatters()
        guard let date = formatters.lazy.compactMap({ $0.date(from: iso8601) }).first else {
            return ""
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private static func makeFormatters() -> [ISO8601DateFormatter] {
        let withFractionalSeconds = ISO8601DateFormatter()
        withFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]

        return [withFractionalSeconds, standard]
    }
}
