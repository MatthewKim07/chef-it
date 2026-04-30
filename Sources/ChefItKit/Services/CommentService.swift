import Foundation

public struct Comment: Codable, Identifiable, Equatable, Sendable {
    public let id: Int
    public let body: String
    public let createdAt: String
    public let userId: Int
    public let displayName: String?
    public let avatarURL: String?

    public init(
        id: Int,
        body: String,
        createdAt: String,
        userId: Int,
        displayName: String?,
        avatarURL: String?
    ) {
        self.id = id
        self.body = body
        self.createdAt = createdAt
        self.userId = userId
        self.displayName = displayName
        self.avatarURL = avatarURL
    }

    enum CodingKeys: String, CodingKey {
        case id
        case body
        case createdAt = "created_at"
        case userId = "user_id"
        case displayName = "display_name"
        case avatarURL = "avatar_url"
    }
}

public enum CommentServiceError: LocalizedError {
    case notAuthenticated
    case notFound
    case networkError(String)
    case serverError(String)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You're not logged in."
        case .notFound: return "We couldn't find that post."
        case .networkError(let message): return "Connection problem: \(message)"
        case .serverError(let message): return "Something went wrong: \(message)"
        }
    }
}

@MainActor
public final class CommentService {
    public static let shared = CommentService()

    private let baseURL = "http://127.0.0.1:3000"
    private struct ErrorBody: Decodable { let error: String }

    public func fetchComments(postId: Int) async throws -> [Comment] {
        guard let url = URL(string: "\(baseURL)/api/posts/\(postId)/comments") else {
            throw CommentServiceError.networkError("Invalid URL")
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        return try decode([Comment].self, data: data, response: response)
    }

    public func createComment(postId: Int, body: String) async throws -> Comment {
        guard let token = AuthService.shared.retrieveToken() else {
            throw CommentServiceError.notAuthenticated
        }
        guard let url = URL(string: "\(baseURL)/api/posts/\(postId)/comments") else {
            throw CommentServiceError.networkError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(["body": body])

        let (data, response) = try await URLSession.shared.data(for: request)
        return try decode(Comment.self, data: data, response: response)
    }

    private func decode<T: Decodable>(_ type: T.Type, data: Data, response: URLResponse) throws -> T {
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 200 || status == 201 {
            return try JSONDecoder().decode(type, from: data)
        }

        let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error ?? "HTTP \(status)"
        switch status {
        case 401: throw CommentServiceError.notAuthenticated
        case 404: throw CommentServiceError.notFound
        default: throw CommentServiceError.serverError(message)
        }
    }
}
