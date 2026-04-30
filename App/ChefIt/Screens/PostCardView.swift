import SwiftUI
import ChefItKit

struct PostCardView: View {
    let post: Post
    let currentUserId: Int?
    let onAuthorTap: (Int) -> Void
    let onImageTap: (Post) -> Void
    let onCommentTap: (Post) -> Void
    let onDelete: (Post) async -> Void
    private let mediaHeight: CGFloat = 280

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            authorRow
            postImage
            captionArea
            footerRow
        }
        .background(ChefitColors.white)
        .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.md, style: .continuous))
        .chefitCardShadow()
    }

    private var authorRow: some View {
        HStack(spacing: ChefitSpacing.sm) {
            Button {
                onAuthorTap(post.userId)
            } label: {
                avatarView
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Button {
                    onAuthorTap(post.userId)
                } label: {
                    Text(post.displayName ?? "Chef")
                        .font(ChefitTypography.label())
                        .foregroundStyle(ChefitColors.sageGreen)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if post.userId == currentUserId {
                deleteButton
            }
        }
        .padding(.horizontal, ChefitSpacing.md)
        .padding(.top, ChefitSpacing.md)
        .padding(.bottom, ChefitSpacing.sm)
        .frame(minHeight: 64)
    }

    private var postImage: some View {
        Button {
            onImageTap(post)
        } label: {
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
            .frame(height: mediaHeight)
            .background(ChefitColors.pistachio.opacity(0.35))
            .clipped()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var captionArea: some View {
        VStack(alignment: .leading, spacing: ChefitSpacing.xs) {
            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(ChefitTypography.body())
                    .foregroundStyle(ChefitColors.text)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, ChefitSpacing.md)
        .padding(.top, ChefitSpacing.md)
        .padding(.bottom, ChefitSpacing.sm)
    }

    private var footerRow: some View {
        HStack {
            Button {
                onCommentTap(post)
            } label: {
                HStack(spacing: ChefitSpacing.xs) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 16, weight: .regular))
                    Text("\(post.commentCount)")
                        .font(ChefitTypography.label())
                }
                .foregroundStyle(ChefitColors.sageGreen)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(relativeTimestamp)
                .font(ChefitTypography.micro())
                .foregroundStyle(ChefitColors.matcha)
        }
        .padding(.horizontal, ChefitSpacing.md)
        .padding(.bottom, ChefitSpacing.md)
    }

    private var deleteButton: some View {
        Menu {
            Button(role: .destructive) {
                Task { await onDelete(post) }
            } label: {
                Label("Delete Post", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ChefitColors.matcha)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
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
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.system(size: 32, weight: .thin))
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

    private var relativeTimestamp: String {
        RelativePostDateFormatter.string(from: post.createdAt)
    }
}
