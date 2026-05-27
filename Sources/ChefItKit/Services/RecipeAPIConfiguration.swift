import Foundation

public struct RecipeAPIConfiguration: Equatable, Sendable {
    public let appID: String
    public let appKey: String
    public let accountUser: String
    public static let defaultAccountUser = "chefit-ios"

    public init(
        appID: String,
        appKey: String,
        accountUser: String = RecipeAPIConfiguration.defaultAccountUser
    ) {
        let trimmedAccountUser = accountUser.trimmingCharacters(in: .whitespacesAndNewlines)
        self.appID = appID
        self.appKey = appKey
        self.accountUser = trimmedAccountUser.isEmpty ? RecipeAPIConfiguration.defaultAccountUser : trimmedAccountUser
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
        let accountUser = firstConfiguredValue(
            environment["EDAMAM_ACCOUNT_USER"],
            bundle.object(forInfoDictionaryKey: "EDAMAM_ACCOUNT_USER") as? String
        ) ?? defaultAccountUser

        guard let appID, let appKey else { return nil }
        return RecipeAPIConfiguration(appID: appID, appKey: appKey, accountUser: accountUser)
    }

    private static func firstConfiguredValue(_ values: String?...) -> String? {
        values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { value in
                !value.isEmpty && !value.hasPrefix("$(")
            }
    }
}
