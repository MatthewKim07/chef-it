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
            #if DEBUG
            return "Recipe search is not configured (missing Edamam credentials in this build)."
            #else
            return "Recipe search is not available right now. Try again later."
            #endif
        case .invalidURL:
            return "Recipe search could not start. Try again."
        case .invalidResponse:
            return "Recipe search returned an unexpected response. Try again."
        case .httpStatus(let status):
            if status == 401 || status == 403 {
                return "Recipe search could not authorize this device. Try again later."
            }
            if status >= 500 {
                return "Recipe search is temporarily busy. Try again in a moment."
            }
            return "Recipe search could not complete (code \(status)). Try again."
        case .decodingFailed:
            return "Recipe results could not be read. Try again."
        case .noSuccessfulResponses:
            return "No recipes were returned. Try different ingredients."
        }
    }
}
