import Combine
import Foundation

public enum DiscoveryWorkspacePhase {
    case needsIngredients
    case staged
    case loading
    case loaded(DiscoveryWorkspaceSnapshot)
    case failed(String)
}

public struct DiscoveryWorkspaceSnapshot: Sendable {
    public let plan: RecipeDiscoveryPlan
    public let candidateCount: Int
    public let results: MatchResults

    public init(
        plan: RecipeDiscoveryPlan,
        candidateCount: Int,
        results: MatchResults
    ) {
        self.plan = plan
        self.candidateCount = candidateCount
        self.results = results
    }
}

public struct AddFeedback: Equatable, Sendable {
    public let added: Int
    public let duplicates: Int
    public let empty: Int

    public var isEmpty: Bool { added == 0 && duplicates == 0 && empty == 0 }

    public var summary: String {
        switch (added, duplicates) {
        case (0, 0):
            return "Nothing to add."
        case (let a, 0):
            return "Added \(a)."
        case (0, let d):
            return "Already on board: \(d)."
        case (let a, let d):
            return "Added \(a), \(d) already on board."
        }
    }
}

public enum BoardEditState: Equatable {
    case idle
    case editing(id: Ingredient.ID, draft: String)
    case duplicateConflict(id: Ingredient.ID, draft: String, existingID: Ingredient.ID)
}

@MainActor
public final class ChefItMilestoneOneViewModel: ObservableObject {
    @Published public var manualEntry: String = "" {
        didSet { recomputeSuggestions() }
    }
    @Published public private(set) var phase: DiscoveryWorkspacePhase = .needsIngredients
    @Published public private(set) var suggestions: [String] = []
    @Published public private(set) var lastAddFeedback: AddFeedback?
    @Published public private(set) var undoableClearSnapshot: [Ingredient]?
    @Published public var editState: BoardEditState = .idle

    public let ingredientStore: IngredientStore

    private let planner: RecipeDiscoveryPlanner
    private let matcher: RecipeMatcher
    private let recipeSearchService: any RecipeSearchService
    private let suggester: IngredientSuggester
    private var ingredientsObservation: AnyCancellable?

    public init(
        ingredientStore: IngredientStore? = nil,
        planner: RecipeDiscoveryPlanner = RecipeDiscoveryPlanner(),
        matcher: RecipeMatcher = RecipeMatcher(),
        recipeSearchService: any RecipeSearchService = LocalSeedRecipeSearchService(),
        suggester: IngredientSuggester = IngredientSuggester()
    ) {
        self.ingredientStore = ingredientStore ?? IngredientStore()
        self.planner = planner
        self.matcher = matcher
        self.recipeSearchService = recipeSearchService
        self.suggester = suggester

        ingredientsObservation = self.ingredientStore.$ingredients.sink { [weak self] ingredients in
            guard let self else { return }
            self.recomputeSuggestions()
            if ingredients.isEmpty {
                self.phase = .needsIngredients
                return
            }
            switch self.phase {
            case .loading:
                break
            default:
                self.phase = .staged
            }
        }
    }

    public var ingredients: [Ingredient] {
        ingredientStore.ingredients
    }

    // MARK: - Manual intake

    public func addManualIngredients() {
        let outcomes = ingredientStore.parseAndAdd(manualEntry)
        manualEntry = ""
        lastAddFeedback = summarize(outcomes)
    }

    public func acceptSuggestion(_ suggestion: String) {
        let outcome = ingredientStore.add(rawName: suggestion)
        lastAddFeedback = summarize([outcome])
        manualEntry = ""
    }

    public func dismissAddFeedback() {
        lastAddFeedback = nil
    }

    // MARK: - Edit

    public func beginEdit(_ id: Ingredient.ID) {
        guard let ingredient = ingredients.first(where: { $0.id == id }) else { return }
        editState = .editing(id: id, draft: ingredient.name)
    }

    public func updateEditDraft(_ draft: String) {
        switch editState {
        case .editing(let id, _):
            editState = .editing(id: id, draft: draft)
        case .duplicateConflict(let id, _, let existingID):
            editState = .duplicateConflict(id: id, draft: draft, existingID: existingID)
        case .idle:
            break
        }
    }

    public func commitEdit() {
        let id: Ingredient.ID
        let draft: String
        switch editState {
        case .editing(let i, let d), .duplicateConflict(let i, let d, _):
            id = i; draft = d
        case .idle:
            return
        }

        switch ingredientStore.rename(id, to: draft) {
        case .renamed, .unchanged, .empty, .notFound:
            editState = .idle
        case .wouldDuplicate(let existingID):
            editState = .duplicateConflict(id: id, draft: draft, existingID: existingID)
        }
    }

    public func cancelEdit() {
        editState = .idle
    }

    // MARK: - Destructive + undo

    public func removeIngredient(_ id: Ingredient.ID) {
        ingredientStore.remove(id)
    }

    public func clearBoard() {
        guard !ingredients.isEmpty else { return }
        undoableClearSnapshot = ingredients
        ingredientStore.clear()
    }

    public func undoClear() {
        guard let snapshot = undoableClearSnapshot else { return }
        ingredientStore.restore(snapshot)
        undoableClearSnapshot = nil
    }

    public func dismissUndo() {
        undoableClearSnapshot = nil
    }

    // MARK: - Discovery

    public func refreshWorkspace(
        dietaryTags: [String] = [],
        maxCookingMinutes: Int? = nil
    ) async {
        guard !ingredients.isEmpty else {
            phase = .needsIngredients
            return
        }
        phase = .loading

        do {
            let plan = planner.makePlan(
                from: ingredients,
                dietaryTags: dietaryTags,
                maxCookingMinutes: maxCookingMinutes
            )
            let candidates = try await recipeSearchService.search(query: plan.query)
            let results = matcher.match(
                ingredients: ingredients,
                recipes: candidates,
                context: plan.matchingContext
            )
            phase = .loaded(
                DiscoveryWorkspaceSnapshot(
                    plan: plan,
                    candidateCount: candidates.count,
                    results: results
                )
            )
        } catch {
            phase = .failed(
                (error as? LocalizedError)?.errorDescription
                    ?? "Recipe search failed. Check the API configuration and try again."
            )
        }
    }

    // MARK: - Helpers

    private func recomputeSuggestions() {
        suggestions = suggester.suggestions(
            for: manualEntry,
            excluding: ingredientStore.canonicalSet
        )
    }

    private func summarize(_ outcomes: [IngredientAddOutcome]) -> AddFeedback {
        var added = 0, dups = 0, empty = 0
        for o in outcomes {
            switch o {
            case .added: added += 1
            case .duplicate: dups += 1
            case .empty: empty += 1
            }
        }
        return AddFeedback(added: added, duplicates: dups, empty: empty)
    }
}
