import Foundation

public struct UserProfile: Codable, Equatable, Sendable {
    public let id: Int
    public let displayName: String?
    public let bio: String?
    public let avatarURL: String?
    public let createdAt: String

    public init(id: Int, displayName: String?, bio: String?, avatarURL: String?, createdAt: String) {
        self.id = id
        self.displayName = displayName
        self.bio = bio
        self.avatarURL = avatarURL
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, bio
        case displayName = "display_name"
        case avatarURL   = "avatar_url"
        case createdAt   = "created_at"
    }
}

public enum UserServiceError: LocalizedError {
    case notAuthenticated
    case forbidden
    case notFound
    case networkError(String)
    case serverError(String)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:     return "You're not logged in."
        case .forbidden:            return "You can only edit your own profile."
        case .notFound:             return "User not found."
        case .networkError(let m):  return "Connection problem: \(m)"
        case .serverError(let m):   return "Something went wrong: \(m)"
        }
    }
}

@MainActor
public final class UserService {
    public static let shared = UserService()

    private let baseURL: String = "http://127.0.0.1:3000"

    private struct ErrorBody: Decodable { let error: String }

    // MARK: - Public API

    public func fetchProfile(id: Int) async throws -> UserProfile {
        guard let url = URL(string: "\(baseURL)/api/users/\(id)") else {
            throw UserServiceError.networkError("Invalid URL")
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        return try decode(UserProfile.self, data: data, response: response)
    }

    public func updateProfile(id: Int, displayName: String?, bio: String?) async throws -> UserProfile {
        guard let token = AuthService.shared.retrieveToken() else {
            throw UserServiceError.notAuthenticated
        }
        guard let url = URL(string: "\(baseURL)/api/users/\(id)") else {
            throw UserServiceError.networkError("Invalid URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body: [String: String] = [:]
        if let name = displayName { body["display_name"] = name }
        if let b = bio { body["bio"] = b }
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)
        return try decode(UserProfile.self, data: data, response: response)
    }

    public func uploadAvatar(id: Int, imageData: Data) async throws -> String {
        guard let token = AuthService.shared.retrieveToken() else {
            throw UserServiceError.notAuthenticated
        }
        guard let url = URL(string: "\(baseURL)/api/users/\(id)/avatar") else {
            throw UserServiceError.networkError("Invalid URL")
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = multipartBody(imageData: imageData, boundary: boundary)

        let (data, response) = try await URLSession.shared.data(for: req)

        struct AvatarResponse: Decodable { let avatar_url: String }
        let parsed = try decode(AvatarResponse.self, data: data, response: response)
        return parsed.avatar_url
    }

    // MARK: - Private helpers

    private func decode<T: Decodable>(_ type: T.Type, data: Data, response: URLResponse) throws -> T {
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 200 || status == 201 {
            return try JSONDecoder().decode(type, from: data)
        }
        let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error ?? "HTTP \(status)"
        switch status {
        case 401: throw UserServiceError.notAuthenticated
        case 403: throw UserServiceError.forbidden
        case 404: throw UserServiceError.notFound
        default:  throw UserServiceError.serverError(message)
        }
    }

    private func multipartBody(imageData: Data, boundary: String) -> Data {
        var body = Data()
        let crlf = "\r\n"
        body.append("--\(boundary)\(crlf)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\(crlf)".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\(crlf)\(crlf)".data(using: .utf8)!)
        body.append(imageData)
        body.append("\(crlf)--\(boundary)--\(crlf)".data(using: .utf8)!)
        return body
    }
}
