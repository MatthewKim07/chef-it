import Foundation

/// Boundary for the photo-scan pipeline.
///
/// In milestone 2 the real implementation will run on-device via VisionKit
/// (DataScannerViewController + image classification) or call a remote vision
/// model. This protocol keeps the call site stable so swapping in the real
/// pipeline is mechanical.
public protocol ScanService: Sendable {
    /// Detect ingredients from raw image bytes. Returns canonicalized
    /// candidates with confidence so the UI can present a confirmable list.
    func detectIngredients(in imageData: Data) async throws -> ScanResult
}

public enum ScanError: Error, Sendable {
    case noIngredientsDetected
    case rateLimited(retryAfterSeconds: Int)
    case backendUnavailable
    case invalidImage
}

/// Stub implementation. Returns deterministic canned results so the UI flow
/// can be exercised end-to-end without a real vision backend.
public struct StubScanService: ScanService {
    public init() {}

    public func detectIngredients(in imageData: Data) async throws -> ScanResult {
        // Simulate latency so loading state is visible during dev.
        try? await Task.sleep(nanoseconds: 600_000_000)

        let normalizer = IngredientNormalizer()
        let raws: [(String, Double, IngredientCategory)] = [
            ("cherry tomatoes", 0.94, .produce),
            ("yellow onion", 0.88, .produce),
            ("fresh garlic", 0.91, .produce),
            ("salted butter", 0.83, .dairy),
            ("extra virgin olive oil", 0.78, .pantry)
        ]
        let candidates = raws.map { raw, confidence, category in
            DetectedIngredient(
                rawName: raw,
                canonicalName: normalizer.canonicalize(raw),
                category: category,
                confidence: confidence
            )
        }
        return ScanResult(candidates: candidates)
    }
}
