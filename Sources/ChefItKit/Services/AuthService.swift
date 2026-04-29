import Foundation
import Security

@MainActor
public final class AuthService: ObservableObject {
    public static let shared = AuthService()

    @Published public private(set) var isLoggedIn: Bool
    @Published public private(set) var currentUser: AuthUser?

    private let baseURL = "http://localhost:3000"
    private let keychainService = "com.chefit.auth"
    private let keychainAccount = "jwt"

    public init() {
        isLoggedIn = false
        isLoggedIn = retrieveToken() != nil
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

    public func logout() {
        deleteToken()
        currentUser = nil
        isLoggedIn = false
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
            throw AuthError.networkError(urlError.localizedDescription)
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        if status == 200 || status == 201 {
            return try JSONDecoder().decode(T.self, from: data)
        }

        let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error ?? "Unknown error"

        switch status {
        case 401: throw AuthError.invalidCredentials
        case 409: throw AuthError.emailAlreadyRegistered
        default:  throw AuthError.serverError(message)
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
