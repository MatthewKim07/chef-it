import SwiftUI
import GoogleSignIn
import ChefItKit

@MainActor
struct GoogleSignInHandler {
    func signIn() async -> Result<String, Error> {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String,
              !clientID.isEmpty,
              !clientID.hasPrefix("$(") else {
            return .failure(GoogleAuthError.missingClientID)
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let topVC = topViewController() else {
            return .failure(GoogleAuthError.noViewController)
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
            guard let idToken = result.user.idToken?.tokenString else {
                return .failure(GoogleAuthError.noIDToken)
            }
            return .success(idToken)
        } catch {
            return .failure(error)
        }
    }

    private func topViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first { $0.isKeyWindow }?
            .rootViewController?
            .topMostViewController()
    }
}

enum GoogleAuthError: LocalizedError {
    case missingClientID
    case noViewController
    case noIDToken

    var errorDescription: String? {
        switch self {
        case .missingClientID:
            return "Google Client ID is not configured. Add GOOGLE_CLIENT_ID to Secrets.xcconfig."
        case .noViewController:
            return "Unable to find a view controller to present Google sign-in."
        case .noIDToken:
            return "Google sign-in did not return an ID token."
        }
    }
}

private extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.topMostViewController() ?? nav
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }
        return self
    }
}
