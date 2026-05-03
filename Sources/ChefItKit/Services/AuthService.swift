import Foundation
import Security

@MainActor
public final class AuthService: ObservableObject {
    public static let shared = AuthService()

    @Published public private(set) var isLoggedIn: Bool
    @Published public private(set) var currentUser: AuthUser?

    private let baseURL: String
    private let keychainService = "com.chefit.auth"
    private let keychainAccount = "jwt"

    public init() {
        baseURL = Self.resolvedBaseURL()
        currentUser = nil
        isLoggedIn = false

        #if DEBUG
        // Testing convenience: always start logged-out in debug builds.
        deleteToken()
        #endif

        if let token = retrieveToken() {
            currentUser = Self.userFromToken(token)
            isLoggedIn = true
        }
    }

    // MARK: - Public API

    public func register(email: String, password: String, displayName: String) async throws -> AuthResponse {
        let body = ["email": email, "password": password, "display_name": displayName]
        let response: AuthResponse = try await post(path: "/api/auth/register", body: body)
        saveToken(response.token)
        currentUser = response.user
        isLoggedIn = true
        return response
    }

    public func login(email: String, password: String) async throws -> AuthResponse {
        let body = ["email": email, "password": password]
        let response: AuthResponse = try await post(path: "/api/auth/login", body: body)
        saveToken(response.token)
        currentUser = response.user
        isLoggedIn = true
        return response
    }

    public func signInWithGoogle(idToken: String) async throws -> AuthResponse {
        let body = ["id_token": idToken]
        let response: AuthResponse = try await post(path: "/api/auth/google", body: body)
        saveToken(response.token)
        currentUser = response.user
        isLoggedIn = true
        return response
    }

    public func signInWithApple(identityToken: String, displayName: String?) async throws -> AuthResponse {
        var body: [String: String] = ["identity_token": identityToken]
        if let displayName = displayName {
            body["display_name"] = displayName
        }
        let response: AuthResponse = try await post(path: "/api/auth/apple", body: body)
        saveToken(response.token)
        currentUser = response.user
        isLoggedIn = true
        return response
    }

    public func logout() {
        deleteToken()
        currentUser = nil
        isLoggedIn = false
    }

    public func changePassword(currentPassword: String, newPassword: String) async throws {
        let body = ["current_password": currentPassword, "new_password": newPassword]
        let _: OkResponse = try await authedRequest(method: "POST", path: "/api/auth/change-password", body: body)
    }

    public func changeEmail(password: String, newEmail: String) async throws -> AuthResponse {
        let body = ["password": password, "new_email": newEmail]
        let response: AuthResponse = try await authedRequest(method: "POST", path: "/api/auth/change-email", body: body)
        saveToken(response.token)
        currentUser = response.user
        return response
    }

    public func deleteAccount(password: String) async throws {
        let body = ["password": password]
        let _: OkResponse = try await authedRequest(method: "DELETE", path: "/api/auth/account", body: body)
        logout()
    }

    public func retrieveToken() -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      keychainService,
            kSecAttrAccount:      keychainAccount,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else { return nil }
        return token
    }

    // MARK: - Network

    private struct ErrorBody: Decodable { let error: String }
    private struct TokenPayload: Decodable {
        let id: Int
        let email: String
    }
    private struct OkResponse: Decodable { let ok: Bool }

    private func post<T: Decodable>(path: String, body: [String: String]) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw AuthError.networkError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            throw AuthError.networkError(Self.connectionHint(for: urlError, baseURL: baseURL))
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        if status == 200 || status == 201 {
            return try JSONDecoder().decode(T.self, from: data)
        }

        let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error ?? "HTTP \(status)"

        switch status {
        case 401: throw AuthError.invalidCredentials
        case 409: throw AuthError.emailAlreadyRegistered
        default:  throw AuthError.serverError(message)
        }
    }

    private func authedRequest<T: Decodable>(method: String, path: String, body: [String: String]) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw AuthError.networkError("Invalid URL")
        }
        guard let token = retrieveToken() else {
            throw AuthError.invalidCredentials
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            throw AuthError.networkError(Self.connectionHint(for: urlError, baseURL: baseURL))
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        if status == 200 || status == 201 || status == 204 {
            if data.isEmpty, let empty = try? JSONDecoder().decode(T.self, from: Data("{\"ok\":true}".utf8)) {
                return empty
            }
            return try JSONDecoder().decode(T.self, from: data)
        }

        let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error ?? "HTTP \(status)"

        switch status {
        case 401: throw AuthError.invalidCredentials
        case 409: throw AuthError.emailAlreadyRegistered
        default:  throw AuthError.serverError(message)
        }
    }

    private static func resolvedBaseURL(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundle: Bundle = .main
    ) -> String {
        firstConfiguredValue(
            environment["AUTH_BASE_URL"],
            bundle.object(forInfoDictionaryKey: "AUTH_BASE_URL") as? String
        ) ?? "http://127.0.0.1:3000"
    }

    private static func firstConfiguredValue(_ values: String?...) -> String? {
        values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { value in
                !value.isEmpty && !value.hasPrefix("$(")
            }
    }

private static func userFromToken(_ token: String) -> AuthUser? {
    let segments = token.split(separator: ".")
    guard segments.count >= 2,
          let payloadData = decodeBase64URL(String(segments[1])),
          let payload = try? JSONDecoder().decode(TokenPayload.self, from: payloadData) else {
        return nil
    }
    return AuthUser(id: payload.id, email: payload.email, displayName: nil)
}

private static func decodeBase64URL(_ value: String) -> Data? {
    var base64 = value
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let remainder = base64.count % 4
    if remainder != 0 {
        base64 += String(repeating: "=", count: 4 - remainder)
    }
    return Data(base64Encoded: base64)
}

/// Clearer than raw URLError when the API isn't reachable (backend down, wrong host, device + localhost).
private static func connectionHint(for error: URLError, baseURL: String) -> String {
    switch error.code {
    case .cannotConnectToHost, .cannotFindHost, .timedOut, .networkConnectionLost:
        var parts: [String] = ["can't reach \(baseURL)."]
        #if os(iOS)
        if !ProcessInfo.processInfo.isiOSAppOnMac {
            #if !targetEnvironment(simulator)
            let lower = baseURL.lowercased()
            if lower.contains("127.0.0.1") || lower.contains("localhost") {
                parts.append(
                    "On a real iPhone/iPad, localhost is the device itself — set AUTH_BASE_URL in Secrets.xcconfig to your Mac's LAN IP (e.g. http://192.168.x.x:3000)."
                )
            }
            #endif
        }
        #endif
        parts.append("Start the API from the repo: cd backend && npm install && npm run dev")
        return parts.joined(separator: " ")
    default:
        return error.localizedDescription
    }
}
    

    // MARK: - Keychain

    private func saveToken(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }

        let addQuery: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
            kSecValueData:   data,
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)

        if status == errSecDuplicateItem {
            let search: [CFString: Any] = [
                kSecClass:       kSecClassGenericPassword,
                kSecAttrService: keychainService,
                kSecAttrAccount: keychainAccount,
            ]
            SecItemUpdate(search as CFDictionary, [kSecValueData: data] as CFDictionary)
        }
    }

    private func deleteToken() {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
