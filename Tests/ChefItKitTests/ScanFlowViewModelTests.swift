import Foundation
import Testing
@testable import ChefItKit

@MainActor
@Suite("ScanFlowViewModel")
struct ScanFlowViewModelTests {
    private struct FixedScanService: ScanService {
        let result: Result<ScanResult, Error>

        func detectIngredients(in imageData: Data) async throws -> ScanResult {
            switch result {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
            }
        }
    }

    private func makeStore() -> IngredientStore {
        IngredientStore(persister: InMemoryIngredientPersister())
    }

    private func makeCandidate(
        rawName: String,
        canonicalName: String,
        category: IngredientCategory = .produce,
        confidence: Double = 0.9
    ) -> DetectedIngredient {
        DetectedIngredient(
            rawName: rawName,
            canonicalName: canonicalName,
            category: category,
            confidence: confidence
        )
    }

    @Test func successfulScanTransitionsToReview() async {
        let store = makeStore()
        let result = ScanResult(candidates: [
            makeCandidate(rawName: "fresh garlic", canonicalName: "garlic"),
            makeCandidate(rawName: "cherry tomatoes", canonicalName: "tomato")
        ])
        let model = ScanFlowViewModel(
            ingredientStore: store,
            scanService: FixedScanService(result: .success(result))
        )

        await model.beginScan(imageData: Data([1, 2, 3]), source: .photoLibrary)

        #expect(model.phase == .review)
        #expect(model.candidates.count == 2)
        #expect(model.selectedCount == 2)
        #expect(model.draft?.source == .photoLibrary)
    }

    @Test func emptyScanTransitionsToEmptyState() async {
        let store = makeStore()
        let model = ScanFlowViewModel(
            ingredientStore: store,
            scanService: FixedScanService(result: .success(ScanResult(candidates: [])))
        )

        await model.beginScan(imageData: Data([9]), source: .camera)

        #expect(model.phase == .empty)
        #expect(model.message == "No ingredients found. Try a tighter photo or better lighting.")
    }

    @Test func failedScanTransitionsToErrorState() async {
        let store = makeStore()
        let model = ScanFlowViewModel(
            ingredientStore: store,
            scanService: FixedScanService(result: .failure(ScanError.backendUnavailable))
        )

        await model.beginScan(imageData: Data([4, 2]), source: .camera)

        #expect(model.phase == .failed)
        #expect(model.message == "Scan backend is unavailable right now.")
    }

    @Test func confirmSelectedAddsScanIngredientsToBoard() async {
        let store = makeStore()
        let result = ScanResult(candidates: [
            makeCandidate(rawName: "fresh garlic", canonicalName: "garlic"),
            makeCandidate(rawName: "cherry tomatoes", canonicalName: "tomato")
        ])
        let model = ScanFlowViewModel(
            ingredientStore: store,
            scanService: FixedScanService(result: .success(result))
        )

        await model.beginScan(imageData: Data([1, 3, 5]), source: .photoLibrary)
        model.confirmSelected()

        #expect(model.phase == .idle)
        #expect(store.ingredients.count == 2)
        #expect(store.ingredients.allSatisfy { $0.source == .scan })
        #expect(model.lastConfirmFeedback?.added == 2)
    }

    @Test func confirmSelectedRejectsEmptySelection() async throws {
        let store = makeStore()
        let result = ScanResult(candidates: [
            makeCandidate(rawName: "fresh garlic", canonicalName: "garlic")
        ])
        let model = ScanFlowViewModel(
            ingredientStore: store,
            scanService: FixedScanService(result: .success(result))
        )

        await model.beginScan(imageData: Data([8]), source: .photoLibrary)
        let onlyID = try #require(model.candidates.first?.id)
        model.toggleCandidate(onlyID)
        model.confirmSelected()

        #expect(model.phase == .review)
        #expect(store.ingredients.isEmpty)
        #expect(model.message == "Select at least one ingredient before adding to the board.")
    }

    @Test func confirmSelectedReportsDuplicatesWithoutAddingSecondCopy() async {
        let store = makeStore()
        _ = store.add(rawName: "garlic")

        let result = ScanResult(candidates: [
            makeCandidate(rawName: "fresh garlic", canonicalName: "garlic")
        ])
        let model = ScanFlowViewModel(
            ingredientStore: store,
            scanService: FixedScanService(result: .success(result))
        )

        await model.beginScan(imageData: Data([7]), source: .camera)
        model.confirmSelected()

        #expect(store.ingredients.count == 1)
        #expect(model.lastConfirmFeedback?.duplicates == 1)
    }
}
