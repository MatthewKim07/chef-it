import SwiftUI
import ChefItKit

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published private(set) var items: [AppNotification] = []
    @Published private(set) var isLoading = false
    @Published private(set) var unreadCount: Int = 0
    @Published var error: String?

    func load() async {
        isLoading = true
        error = nil
        do {
            items = try await NotificationService.shared.fetchAll()
            unreadCount = items.filter { $0.isUnread }.count
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func refreshUnreadCount() async {
        do {
            unreadCount = try await NotificationService.shared.unreadCount()
        } catch {
            // silent — badge just won't update
        }
    }

    func markAllRead() async {
        do {
            try await NotificationService.shared.markAllRead()
            unreadCount = 0
        } catch {
            // silent
        }
    }
}

struct ChefitNotificationsView: View {
    let onBack: () -> Void
    let onPostTap: (Int) -> Void
    let onActorTap: (Int) -> Void

    @StateObject private var vm = NotificationsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header

            if vm.isLoading && vm.items.isEmpty {
                Spacer()
                ProgressView().tint(ChefitColors.sageGreen)
                Spacer()
            } else if vm.items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.items) { item in
                            NotificationRowView(
                                item: item,
                                onTap: {
                                    if let pid = item.postId { onPostTap(pid) }
                                },
                                onActorTap: { onActorTap(item.actorId) }
                            )
                        }
                    }
                    .padding(.horizontal, ChefitSpacing.md)
                    .padding(.top, ChefitSpacing.sm)
                    .padding(.bottom, ChefitSpacing.xl)
                }
                .refreshable { await vm.load() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChefitColors.cream.ignoresSafeArea())
        .task {
            await vm.load()
            await vm.markAllRead()
        }
    }

    private var header: some View {
        ZStack {
            Text("Notifications")
                .font(.custom("Nunito-Bold", size: 22))
                .foregroundStyle(ChefitColors.text)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(ChefitColors.sageGreen)
                        .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                Spacer()
            }
        }
        .padding(.horizontal, ChefitSpacing.md)
        .padding(.top, ChefitSpacing.sm)
        .padding(.bottom, ChefitSpacing.md)
    }

    private var emptyState: some View {
        VStack(spacing: ChefitSpacing.md) {
            Spacer()
            Image(systemName: "bell")
                .font(.system(size: 44, weight: .thin))
                .foregroundStyle(ChefitColors.matcha)
            Text("No notifications yet")
                .font(ChefitTypography.h3())
                .foregroundStyle(ChefitColors.sageGreen)
            Text("Likes and comments on your posts will show up here.")
                .font(ChefitTypography.body())
                .foregroundStyle(ChefitColors.matcha)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ChefitSpacing.lg)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct NotificationRowView: View {
    let item: AppNotification
    let onTap: () -> Void
    let onActorTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: ChefitSpacing.sm) {
                Button(action: onActorTap) {
                    avatar
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    messageText
                    Text(RelativePostDateFormatter.string(from: item.createdAt))
                        .font(ChefitTypography.micro())
                        .foregroundStyle(ChefitColors.matcha)
                }

                Spacer(minLength: ChefitSpacing.sm)

                postThumbnail
            }
            .padding(.vertical, ChefitSpacing.sm)
            .padding(.horizontal, ChefitSpacing.sm)
            .background(item.isUnread ? ChefitColors.peach.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.sm, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var messageText: some View {
        let actor = item.actorDisplayName ?? "Someone"
        let action: String = {
            switch item.type {
            case "like":    return "liked your post"
            case "comment": return "commented on your post"
            default:        return "interacted with your post"
            }
        }()

        return (
            Text(actor)
                .font(ChefitTypography.label())
                .foregroundStyle(ChefitColors.sageGreen)
            + Text(" \(action)")
                .font(ChefitTypography.body())
                .foregroundStyle(ChefitColors.text.opacity(0.85))
        )
        .multilineTextAlignment(.leading)
        .lineLimit(3)
    }

    private var avatar: some View {
        Group {
            if let urlStr = item.actorAvatarURL, let url = URL(string: urlStr) {
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
        .frame(width: 44, height: 44)
        .clipShape(Circle())
        .overlay(Circle().stroke(ChefitColors.pistachio, lineWidth: 1.5))
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(ChefitColors.pistachio)
            .overlay {
                Image(systemName: "person")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(ChefitColors.matcha)
            }
    }

    @ViewBuilder
    private var postThumbnail: some View {
        if let urlStr = item.postImageURL, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    thumbnailPlaceholder
                }
            }
            .frame(width: 44, height: 44)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.sm, style: .continuous))
        } else {
            thumbnailPlaceholder
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: ChefitRadius.sm, style: .continuous))
        }
    }

    private var thumbnailPlaceholder: some View {
        Rectangle()
            .fill(ChefitColors.pistachio)
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.system(size: 14, weight: .thin))
                    .foregroundStyle(ChefitColors.matcha)
            }
    }
}
