import Combine
import Foundation

public enum ScanSourceKind: String, Hashable, Sendable {
    case photoLibrary
    case camera

    public var label: String {
        switch self {
        case .photoLibrary:
            return "Photo Library"
        case .camera:
            return "Camera"
        }
    }
}

public enum ScanFlowPhase: Equatable, Sendable {
    case idle
    case analyzing
    case review
    case empty
    case failed
}

public struct ScanDraft: Equatable, Sendable {
    public let imageData: Data
    public let source: ScanSourceKind

    public init(imageData: Data, source: ScanSourceKind) {
        self.imageData = imageData
        self.source = source
    }
}

public struct ScanCandidate: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let rawName: String
    public let canonicalName: String
    public let category: IngredientCategory
    public let confidence: Double
    public var isSelected: Bool

    public init(detected: DetectedIngredient, isSelected: Bool = true) {
        self.id = detected.id
        self.rawName = detected.rawName
        self.canonicalName = detected.canonicalName
        self.category = detected.category
        self.confidence = detected.confidence
        self.isSelected = isSelected
    }
}

@MainActor
public final class ScanFlowViewModel: ObservableObject {
    @Published public private(set) var phase: ScanFlowPhase = .idle
    @Published public private(set) var draft: ScanDraft?
    @Published public private(set) var candidates: [ScanCandidate] = []
    @Published public private(set) var message: String?
    @Published public private(set) var lastConfirmFeedback: AddFeedback?

    private let ingredientStore: IngredientStore
    private let scanService: any ScanService
    private let normalizer = IngredientNormalizer()

    public init(
        ingredientStore: IngredientStore,
        scanService: any ScanService = StubScanService()
    ) {
        self.ingredientStore = ingredientStore
        self.scanService = scanService
    }

    public var selectedCount: Int {
        candidates.filter(\.isSelected).count
    }

    public func beginScan(imageData: Data, source: ScanSourceKind) async {
        draft = ScanDraft(imageData: imageData, source: source)
        candidates = []
        message = nil
        lastConfirmFeedback = nil

        guard !imageData.isEmpty else {
            phase = .failed
            message = message(for: ScanError.invalidImage)
            return
        }

        phase = .analyzing

        do {
            let result = try await scanService.detectIngredients(in: imageData)
            if result.candidates.isEmpty {
                phase = .empty
                message = "No ingredients found. Try a tighter photo or better lighting."
                return
            }

            candidates = result.candidates.map { ScanCandidate(detected: $0) }
            phase = .review
        } catch {
            phase = .failed
            message = message(for: error)
        }
    }

    public func toggleCandidate(_ id: UUID) {
        guard let index = candidates.firstIndex(where: { $0.id == id }) else { return }
        candidates[index].isSelected.toggle()
        message = nil
    }

    @discardableResult
    public func confirmSelected() -> Bool {
        let selected = candidates.filter(\.isSelected)
        guard !selected.isEmpty else {
            message = "Select at least one ingredient before adding to the board."
            return false
        }

        let outcomes = ingredientStore.addMany(
            selected.map(\.rawName),
            source: .scan
        )
        lastConfirmFeedback = summarize(outcomes)
        clearSession(preserveFeedback: true)
        return true
    }

    public func addManualCandidate(_ rawName: String) {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let canonical = normalizer.canonicalize(trimmed)
        guard !canonical.isEmpty else {
            message = "Type an ingredient name before adding."
            return
        }

        if let existingIndex = candidates.firstIndex(where: { $0.canonicalName == canonical }) {
            candidates[existingIndex].isSelected = true
            message = nil
            return
        }

        let detected = DetectedIngredient(
            rawName: trimmed,
            canonicalName: canonical,
            category: normalizer.category(for: canonical),
            confidence: 1.0
        )
        candidates.append(ScanCandidate(detected: detected, isSelected: true))
        message = nil
    }

    public func retry() async {
        guard let draft else { return }
        await beginScan(imageData: draft.imageData, source: draft.source)
    }

    public func dismissFeedback() {
        lastConfirmFeedback = nil
    }

    public func reset() {
        clearSession(preserveFeedback: false)
    }

    private func clearSession(preserveFeedback: Bool) {
        phase = .idle
        draft = nil
        candidates = []
        message = nil
        if !preserveFeedback {
            lastConfirmFeedback = nil
        }
    }

    private func summarize(_ outcomes: [IngredientAddOutcome]) -> AddFeedback {
        var added = 0
        var duplicates = 0
        var empty = 0

        for outcome in outcomes {
            switch outcome {
            case .added:
                added += 1
            case .duplicate:
                duplicates += 1
            case .empty:
                empty += 1
            }
        }

        return AddFeedback(added: added, duplicates: duplicates, empty: empty)
    }

    private func message(for error: Error) -> String {
        guard let scanError = error as? ScanError else {
            return "Scan failed. Try another image."
        }

        switch scanError {
        case .noIngredientsDetected:
            return "No ingredients found. Try a tighter photo or better lighting."
        case .rateLimited(let retryAfterSeconds):
            return "Scan temporarily limited. Try again in \(retryAfterSeconds)s."
        case .backendUnavailable:
            return "Scan backend is unavailable right now."
        case .invalidImage:
            return "That image could not be read."
        }
    }
}
