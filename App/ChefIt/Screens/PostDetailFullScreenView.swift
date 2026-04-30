import SwiftUI
import ChefItKit

struct PostDetailFullScreenView: View {
    let post: Post
    let currentUserId: Int?
    let onBack: () -> Void
    let onDelete: ((Post) async -> Void)?

    @State private var showDeleteConfirm = false
    @State private var isDeleting = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: 56)

                    postImage

                    VStack(alignment: .leading, spacing: ChefitSpacing.md) {
                        authorRow

                        if let caption = post.caption, !caption.isEmpty {
                            Text(caption)
                                .font(ChefitTypography.body())
                                .foregroundStyle(ChefitColors.text)
                        }

                        commentSummary

                        commentsPlaceholder

                        if post.userId == currentUserId {
                            deleteButton
                        }
                    }
                    .padding(ChefitSpacing.md)

                    Color.clear.frame(height: ChefitSpacing.twoXL)
                }
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
        .background(ChefitColors.cream.ignoresSafeArea())
        .confirmationDialog("Delete this post?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    isDeleting = true
                    await onDelete?(post)
                    isDeleting = false
                    onBack()
                }
            }
        } message: {
            Text("This can't be undone.")
        }
    }

    private var postImage: some View {
        Group {
            if let urlStr = post.imageURL, let url = URL(string: urlStr) {
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
                Text(post.displayName ?? "Chef")
                    .font(ChefitTypography.label())
                    .foregroundStyle(ChefitColors.sageGreen)

                Text(RelativePostDateFormatter.string(from: post.createdAt))
                    .font(ChefitTypography.micro())
                    .foregroundStyle(ChefitColors.matcha)
            }

            Spacer()
        }
    }

    private var commentSummary: some View {
        HStack(spacing: ChefitSpacing.xs) {
            Image(systemName: "bubble.left")
                .font(.system(size: 14, weight: .regular))
            Text("\(post.commentCount) comments")
                .font(ChefitTypography.label())
        }
        .foregroundStyle(ChefitColors.sageGreen.opacity(0.82))
    }

    private var commentsPlaceholder: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.sm) {
            Divider()
                .overlay(ChefitColors.pistachio)

            Text("Comments")
                .font(ChefitTypography.h3())
                .foregroundStyle(ChefitColors.sageGreen)

            VStack(spacing: ChefitSpacing.sm) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 30, weight: .thin))
                    .foregroundStyle(ChefitColors.matcha)

                Text("Comments will show up here next.")
                    .font(ChefitTypography.body())
                    .foregroundStyle(ChefitColors.matcha)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ChefitSpacing.xl)
        }
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
            if let urlStr = post.avatarURL, let url = URL(string: urlStr) {
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
