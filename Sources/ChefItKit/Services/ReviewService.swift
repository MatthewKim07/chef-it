import Foundation

public struct Review: Codable, Identifiable, Equatable, Sendable {
    public let id: Int
    public let rating: Int
    public let body: String?
    public let createdAt: String
    public let userId: Int
    public let displayName: String?
    public let avatarURL: String?

    public init(
        id: Int,
        rating: Int,
        body: String?,
        createdAt: String,
        userId: Int,
        displayName: String?,
        avatarURL: String?
    ) {
        self.id = id
        self.rating = rating
        self.body = body
        self.createdAt = createdAt
        self.userId = userId
        self.displayName = displayName
        self.avatarURL = avatarURL
    }

    enum CodingKeys: String, CodingKey {
        case id
        case rating
        case body
        case createdAt = "created_at"
        case userId = "user_id"
        case displayName = "display_name"
        case avatarURL = "avatar_url"
    }
}

public enum ReviewServiceError: LocalizedError {
    case notAuthenticated
    case networkError(String)
    case serverError(String)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You're not logged in."
        case .networkError(let message): return "Connection problem: \(message)"
        case .serverError(let message): return "Something went wrong: \(message)"
        }
    }
}

@MainActor
public final class ReviewService {
    public static let shared = ReviewService()

    private let baseURL = "http://127.0.0.1:3000"
    private struct ErrorBody: Decodable { let error: String }
    private struct ReviewRequest: Encodable {
        let rating: Int
        let body: String?
    }

    public func fetchReviews(recipeId: String) async throws -> [Review] {
        guard let encodedId = recipeId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/api/recipes/\(encodedId)/reviews") else {
            throw ReviewServiceError.networkError("Invalid URL")
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        return try decode([Review].self, data: data, response: response)
    }

    public func upsertReview(recipeId: String, rating: Int, body: String?) async throws -> Review {
        guard let token = AuthService.shared.retrieveToken() else {
            throw ReviewServiceError.notAuthenticated
        }
        guard let encodedId = recipeId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/api/recipes/\(encodedId)/reviews") else {
            throw ReviewServiceError.networkError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            ReviewRequest(rating: rating, body: body)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        return try decode(Review.self, data: data, response: response)
    }

    private func decode<T: Decodable>(_ type: T.Type, data: Data, response: URLResponse) throws -> T {
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 200 || status == 201 {
            return try JSONDecoder().decode(type, from: data)
        }

        let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error ?? "HTTP \(status)"
        switch status {
        case 401: throw ReviewServiceError.notAuthenticated
        default: throw ReviewServiceError.serverError(message)
        }
    }
}
