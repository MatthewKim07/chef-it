import Foundation

public struct PostsPage: Decodable, Sendable {
    public let posts: [Post]
    public let total: Int

    public var hasMore: Bool {
        posts.count < total
    }
}

public struct Post: Codable, Identifiable, Equatable, Sendable {
    public let id: Int
    public let recipeId: String?
    public let caption: String?
    public let imageURL: String?
    public let createdAt: String
    public let userId: Int
    public let displayName: String?
    public let avatarURL: String?
    public let commentCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case recipeId    = "recipe_id"
        case caption
        case imageURL    = "image_url"
        case createdAt   = "created_at"
        case userId      = "user_id"
        case displayName = "display_name"
        case avatarURL   = "avatar_url"
        case commentCount = "comment_count"
    }
}

public enum PostServiceError: LocalizedError {
    case notAuthenticated
    case forbidden
    case notFound
    case networkError(String)
    case serverError(String)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:    return "You're not logged in."
        case .forbidden:           return "You can only delete your own posts."
        case .notFound:            return "Post not found."
        case .networkError(let m): return "Connection problem: \(m)"
        case .serverError(let m):  return "Something went wrong: \(m)"
        }
    }
}

@MainActor
public final class PostService {
    public static let shared = PostService()
    private let baseURL = "http://127.0.0.1:3000"
    private struct ErrorBody: Decodable { let error: String }

    public func fetchPosts(userId: Int? = nil, limit: Int = 20, offset: Int = 0) async throws -> PostsPage {
        var urlStr = "\(baseURL)/api/posts?limit=\(limit)&offset=\(offset)"
        if let uid = userId { urlStr += "&user_id=\(uid)" }
        guard let url = URL(string: urlStr) else { throw PostServiceError.networkError("Invalid URL") }
        let (data, response) = try await URLSession.shared.data(from: url)
        return try decode(PostsPage.self, data: data, response: response)
    }

    public func fetchPost(id: Int) async throws -> Post {
        guard let url = URL(string: "\(baseURL)/api/posts/\(id)") else {
            throw PostServiceError.networkError("Invalid URL")
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        return try decode(Post.self, data: data, response: response)
    }

    public func hasMorePosts(loadedCount: Int, totalCount: Int) -> Bool {
        loadedCount < totalCount
    }

    public func createPost(caption: String, imageData: Data, recipeId: String? = nil) async throws -> Post {
        guard let token = AuthService.shared.retrieveToken() else { throw PostServiceError.notAuthenticated }
        guard let url = URL(string: "\(baseURL)/api/posts") else { throw PostServiceError.networkError("Invalid URL") }

        let boundary = "Boundary-\(UUID().uuidString)"
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = buildMultipart(caption: caption, imageData: imageData, recipeId: recipeId, boundary: boundary)

        let (data, response) = try await URLSession.shared.data(for: req)
        return try decode(Post.self, data: data, response: response)
    }

    public func deletePost(id: Int) async throws {
        guard let token = AuthService.shared.retrieveToken() else { throw PostServiceError.notAuthenticated }
        guard let url = URL(string: "\(baseURL)/api/posts/\(id)") else {
            throw PostServiceError.networkError("Invalid URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 200 { return }
        let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error ?? "HTTP \(status)"
        switch status {
        case 401: throw PostServiceError.notAuthenticated
        case 403: throw PostServiceError.forbidden
        case 404: throw PostServiceError.notFound
        default:  throw PostServiceError.serverError(message)
        }
    }

    // MARK: - Private

    private func decode<T: Decodable>(_ type: T.Type, data: Data, response: URLResponse) throws -> T {
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 200 || status == 201 { return try JSONDecoder().decode(type, from: data) }
        let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error ?? "HTTP \(status)"
        switch status {
        case 401: throw PostServiceError.notAuthenticated
        case 403: throw PostServiceError.forbidden
        case 404: throw PostServiceError.notFound
        default:  throw PostServiceError.serverError(message)
        }
    }

    private func buildMultipart(caption: String, imageData: Data, recipeId: String?, boundary: String) -> Data {
        var body = Data()
        let crlf = "\r\n"
        func str(_ s: String) { body.append(s.data(using: .utf8)!) }

        str("--\(boundary)\(crlf)")
        str("Content-Disposition: form-data; name=\"caption\"\(crlf)\(crlf)")
        str(caption)
        str(crlf)

        if let rid = recipeId, !rid.isEmpty {
            str("--\(boundary)\(crlf)")
            str("Content-Disposition: form-data; name=\"recipe_id\"\(crlf)\(crlf)")
            str(rid)
            str(crlf)
        }

        str("--\(boundary)\(crlf)")
        str("Content-Disposition: form-data; name=\"image\"; filename=\"post.jpg\"\(crlf)")
        str("Content-Type: image/jpeg\(crlf)\(crlf)")
        body.append(imageData)
        str("\(crlf)--\(boundary)--\(crlf)")

        return body
    }
}
