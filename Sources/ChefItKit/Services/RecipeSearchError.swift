import Foundation

public enum RecipeSearchError: Error, Equatable, LocalizedError, Sendable {
    case missingCredentials
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed
    case noSuccessfulResponses

    public var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "Recipe API credentials are missing. Set EDAMAM_APP_ID and EDAMAM_APP_KEY before running live discovery."
        case .invalidURL:
            return "Recipe search could not build a valid API request."
        case .invalidResponse:
            return "Recipe search returned an invalid response."
        case .httpStatus(let status):
            return "Recipe search failed with HTTP \(status)."
        case .decodingFailed:
            return "Recipe search returned data Chef It could not read."
        case .noSuccessfulResponses:
            return "Recipe search did not return any successful responses."
        }
    }
}
