import Foundation

public struct RecipeAPIConfiguration: Equatable, Sendable {
    public let appID: String
    public let appKey: String

    public init(appID: String, appKey: String) {
        self.appID = appID
        self.appKey = appKey
    }

    public static func fromEnvironment(
        _ environment: [String: String] = ProcessInfo.processInfo.environment,
        bundle: Bundle = .main
    ) -> RecipeAPIConfiguration? {
        let appID = firstConfiguredValue(
            environment["EDAMAM_APP_ID"],
            bundle.object(forInfoDictionaryKey: "EDAMAM_APP_ID") as? String
        )
        let appKey = firstConfiguredValue(
            environment["EDAMAM_APP_KEY"],
            bundle.object(forInfoDictionaryKey: "EDAMAM_APP_KEY") as? String
        )

        guard let appID, let appKey else { return nil }
        return RecipeAPIConfiguration(appID: appID, appKey: appKey)
    }

    private static func firstConfiguredValue(_ values: String?...) -> String? {
        values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { value in
                !value.isEmpty && !value.hasPrefix("$(")
            }
    }
}
