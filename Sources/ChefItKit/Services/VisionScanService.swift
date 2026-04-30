import Foundation

private actor RateLimiter {
    private var lastRequestTime: Date = .distantPast
    private let minInterval: TimeInterval

    init(requestsPerSecond: Double = 1) {
        minInterval = 1.0 / requestsPerSecond
    }

    func waitIfNeeded() async throws {
        let elapsed = Date().timeIntervalSince(lastRequestTime)
        if elapsed < minInterval {
            let delay = minInterval - elapsed
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        lastRequestTime = Date()
    }
}

private actor SessionTracker {
    private(set) var requestCount = 0
    private(set) var totalTokensUsed = 0

    func recordRequest(tokens: Int) {
        requestCount += 1
        totalTokensUsed += tokens
    }
}

public struct VisionScanService: ScanService {
    private let apiKey: String
    private let rateLimiter = RateLimiter(requestsPerSecond: 1)
    private let session = SessionTracker()

    private static let maxInputBytes = 2 * 1024 * 1024
    private static let maxOutputTokens = 400
    private static let requestTimeoutSeconds: TimeInterval = 15

    public init() {
        let raw = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
        apiKey = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func detectIngredients(in imageData: Data) async throws -> ScanResult {
        guard imageData.count <= Self.maxInputBytes else {
            throw ScanError.backendUnavailable
        }
        try await rateLimiter.waitIfNeeded()
        return try await attempt(imageData: imageData, retryCount: 0)
    }

    private func attempt(imageData: Data, retryCount: Int) async throws -> ScanResult {
        guard !apiKey.isEmpty, !apiKey.hasPrefix("$(") else {
            print("[VisionScan] ERROR: API key not configured")
            throw ScanError.backendUnavailable
        }

        let base64 = imageData.base64EncodedString()
        let urlStr = "https://api.openai.com/v1/chat/completions"
        var request = URLRequest(url: URL(string: urlStr)!, timeoutInterval: Self.requestTimeoutSeconds)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "max_tokens": Self.maxOutputTokens,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "List food ingredients visible. Return ONLY a JSON array. " +
                                    "Lowercase generic names. " +
                                    "Format: [{\"name\":\"egg\",\"confidence\":0.9,\"category\":\"protein\"}]. " +
                                    "Categories: produce|protein|dairy|pantry|spice|grain|condiment|other."
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64)",
                                "detail": "low"
                            ]
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("[VisionScan] Sending request, image size: \(imageData.count) bytes")
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            print("[VisionScan] Request timed out")
            throw ScanError.backendUnavailable
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        print("[VisionScan] HTTP status: \(status)")

        switch status {
        case 200: break
        case 429:
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            print("[VisionScan] 429: \(bodyStr)")
            guard retryCount < 1 else {
                throw ScanError.rateLimited(retryAfterSeconds: 30)
            }
            try await Task.sleep(nanoseconds: 32 * 1_000_000_000)
            return try await attempt(imageData: imageData, retryCount: retryCount + 1)
        default:
            let bodyStr = String(data: data, encoding: .utf8) ?? "(unreadable)"
            print("[VisionScan] ERROR \(status): \(bodyStr)")
            throw ScanError.backendUnavailable
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw ScanError.noIngredientsDetected
        }

        if let usage = json["usage"] as? [String: Any] {
            let tokens = (usage["total_tokens"] as? Int) ?? 0
            await session.recordRequest(tokens: tokens)
            #if DEBUG
            let count = await session.requestCount
            let total = await session.totalTokensUsed
            print("[VisionScan] req #\(count) — \(tokens) tokens, \(total) session total")
            #endif
        }

        return try parse(text)
    }

    private func parse(_ text: String) throws -> ScanResult {
        let jsonText: String
        if let range = text.range(of: #"\[[\s\S]*\]"#, options: .regularExpression) {
            jsonText = String(text[range])
        } else {
            jsonText = text
        }

        guard let jsonData = jsonText.data(using: .utf8),
              let items = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            throw ScanError.noIngredientsDetected
        }

        let normalizer = IngredientNormalizer()
        let candidates = items.compactMap { item -> DetectedIngredient? in
            guard let name = item["name"] as? String, !name.isEmpty else { return nil }
            let confidence = item["confidence"] as? Double ?? 0.8
            let category = categoryMap[(item["category"] as? String ?? "other").lowercased()] ?? .other
            return DetectedIngredient(
                rawName: name,
                canonicalName: normalizer.canonicalize(name),
                category: category,
                confidence: confidence
            )
        }

        guard !candidates.isEmpty else { throw ScanError.noIngredientsDetected }
        return ScanResult(candidates: candidates)
    }

    private let categoryMap: [String: IngredientCategory] = [
        "produce":   .produce,
        "protein":   .protein,
        "meat":      .protein,
        "dairy":     .dairy,
        "pantry":    .pantry,
        "spice":     .spice,
        "grain":     .grain,
        "condiment": .condiment,
        "other":     .other
    ]
}
