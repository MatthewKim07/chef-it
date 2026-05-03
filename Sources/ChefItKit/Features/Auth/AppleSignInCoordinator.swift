import SwiftUI
import AuthenticationServices
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Coordinates native Sign in with Apple and returns the identity token.
@MainActor
public final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<Result<(identityToken: String, displayName: String?), Error>, Never>?

    public func signIn() async -> Result<(identityToken: String, displayName: String?), Error> {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    // MARK: - ASAuthorizationControllerDelegate

    nonisolated public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            MainActor.assumeIsolated {
                continuation?.resume(returning: .failure(AppleAuthError.noCredential))
                continuation = nil
            }
            return
        }

        guard let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else {
            MainActor.assumeIsolated {
                continuation?.resume(returning: .failure(AppleAuthError.noIdentityToken))
                continuation = nil
            }
            return
        }

        let displayName: String? = {
            let name = credential.fullName
            let parts = [name?.givenName, name?.familyName].compactMap { $0 }
            return parts.isEmpty ? nil : parts.joined(separator: " ")
        }()

        MainActor.assumeIsolated {
            continuation?.resume(returning: .success((identityToken: identityToken, displayName: displayName)))
            continuation = nil
        }
    }

    nonisolated public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        MainActor.assumeIsolated {
            continuation?.resume(returning: .failure(error))
            continuation = nil
        }
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding

    nonisolated public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            #if canImport(UIKit)
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?
                .windows
                .first { $0.isKeyWindow } ?? UIWindow()
            #elseif canImport(AppKit)
            NSApplication.shared.keyWindow ?? NSWindow()
            #else
            fatalError("Unsupported platform")
            #endif
        }
    }
}

public enum AppleAuthError: LocalizedError {
    case noCredential
    case noIdentityToken

    public var errorDescription: String? {
        switch self {
        case .noCredential:
            return "Apple sign-in did not return valid credentials."
        case .noIdentityToken:
            return "Apple sign-in did not return an identity token."
        }
    }
}
