import Foundation

public struct AuthUser: Codable, Equatable, Sendable {
    public let id: Int
    public let email: String
    public let displayName: String?

    enum CodingKeys: String, CodingKey {
        case id, email
        case displayName = "display_name"
    }
}

public struct AuthResponse: Codable, Sendable {
    public let token: String
    public let user: AuthUser
}

public enum AuthError: LocalizedError, Equatable {
    case invalidCredentials
    case emailAlreadyRegistered
    case networkError(String)
    case serverError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Wrong email or password. Please try again."
        case .emailAlreadyRegistered:
            return "That email is already registered. Try logging in instead."
        case .networkError(let msg):
            return "Connection problem: \(msg)"
        case .serverError(let msg):
            return "Something went wrong: \(msg)"
        }
    }
}
