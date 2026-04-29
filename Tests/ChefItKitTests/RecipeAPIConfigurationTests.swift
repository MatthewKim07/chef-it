import Foundation
import Testing
@testable import ChefItKit

@Suite("RecipeAPIConfiguration")
struct RecipeAPIConfigurationTests {
    @Test func readsCredentialsFromEnvironment() throws {
        let configuration = try #require(
            RecipeAPIConfiguration.fromEnvironment([
                "EDAMAM_APP_ID": " app-id ",
                "EDAMAM_APP_KEY": " app-key "
            ])
        )

        #expect(configuration.appID == "app-id")
        #expect(configuration.appKey == "app-key")
    }

    @Test func ignoresMissingAndUnresolvedBuildSettings() {
        let configuration = RecipeAPIConfiguration.fromEnvironment([
            "EDAMAM_APP_ID": "$(EDAMAM_APP_ID)",
            "EDAMAM_APP_KEY": ""
        ])

        #expect(configuration == nil)
    }
}
