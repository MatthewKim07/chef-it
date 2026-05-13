import Foundation

/// Maps technical errors to short, user-appropriate copy for banners and alerts.
public enum UserFacingErrorMessage {
    public static func message(for error: Error) -> String {
        if error is DecodingError {
            return "We couldn’t read that information. Please try again."
        }

        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return description
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return "You appear to be offline. Check your connection and try again."
            case NSURLErrorTimedOut:
                return "The request timed out. Please try again."
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                return "We could not reach the server. Try again in a moment."
            case NSURLErrorCancelled:
                return "The request was cancelled."
            default:
                break
            }
        }

        let raw = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty || raw == "The operation couldn’t be completed." {
            return "Something went wrong. Please try again."
        }
        if raw.count > 200 {
            return String(raw.prefix(197)) + "…"
        }
        return raw
    }
}
