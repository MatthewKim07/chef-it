import Foundation

public struct AppNotification: Decodable, Identifiable, Equatable, Sendable {
    public let id: Int
    public let type: String
    public let postId: Int?
    public let commentId: Int?
    public let readAt: String?
    public let createdAt: String
    public let actorId: Int
    public let actorDisplayName: String?
    public let actorAvatarURL: String?
    public let postImageURL: String?

    public var isLike: Bool { type == "like" }
    public var isComment: Bool { type == "comment" }
    public var isUnread: Bool { readAt == nil }

    enum CodingKeys: String, CodingKey {
        case id, type
        case postId           = "post_id"
        case commentId        = "comment_id"
        case readAt           = "read_at"
        case createdAt        = "created_at"
        case actorId          = "actor_id"
        case actorDisplayName = "actor_display_name"
        case actorAvatarURL   = "actor_avatar_url"
        case postImageURL     = "post_image_url"
    }
}

public struct NotificationsPage: Decodable, Sendable {
    public let notifications: [AppNotification]
}

public struct UnreadCountResponse: Decodable, Sendable {
    public let count: Int
}

public enum NotificationServiceError: LocalizedError {
    case notAuthenticated
    case networkError(String)
    case serverError(String)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You're not logged in."
        case .networkError(let m): return "Connection problem: \(m)"
        case .serverError(let m): return "Something went wrong: \(m)"
        }
    }
}

@MainActor
public final class NotificationService {
    public static let shared = NotificationService()
    private let baseURL = "http://127.0.0.1:3000"
    private struct ErrorBody: Decodable { let error: String }
    private struct OkResponse: Decodable { let ok: Bool }

    public func fetchAll() async throws -> [AppNotification] {
        let page: NotificationsPage = try await get(path: "/api/notifications")
        return page.notifications
    }

    public func unreadCount() async throws -> Int {
        let response: UnreadCountResponse = try await get(path: "/api/notifications/unread-count")
        return response.count
    }

    public func markAllRead() async throws {
        let _: OkResponse = try await post(path: "/api/notifications/read-all")
    }

    private func get<T: Decodable>(path: String) async throws -> T {
        try await send(method: "GET", path: path)
    }

    private func post<T: Decodable>(path: String) async throws -> T {
        try await send(method: "POST", path: path)
    }

    private func send<T: Decodable>(method: String, path: String) async throws -> T {
        guard let token = AuthService.shared.retrieveToken() else {
            throw NotificationServiceError.notAuthenticated
        }
        guard let url = URL(string: baseURL + path) else {
            throw NotificationServiceError.networkError("Invalid URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 200 || status == 201 {
            return try JSONDecoder().decode(T.self, from: data)
        }
        let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error ?? "HTTP \(status)"
        switch status {
        case 401: throw NotificationServiceError.notAuthenticated
        default:  throw NotificationServiceError.serverError(message)
        }
    }
}
