import Foundation

/// Resolves the backend base URL from the environment, the app's Info.plist
/// (populated from `AUTH_BASE_URL` in Secrets.xcconfig), or a localhost fallback.
public enum APIConfig {
    public static func resolvedBaseURL(
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
}
