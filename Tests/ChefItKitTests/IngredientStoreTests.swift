import Testing
@testable import ChefItKit

@MainActor
@Suite("IngredientStore")
struct IngredientStoreTests {
    private func makeStore(initial: [Ingredient] = []) -> (IngredientStore, InMemoryIngredientPersister) {
        let persister = InMemoryIngredientPersister(initial)
        let store = IngredientStore(persister: persister)
        return (store, persister)
    }

    @Test func addsCanonicalizesAndDedupes() {
        let (store, _) = makeStore()
        if case .added = store.add(rawName: "Cherry Tomatoes") {} else { Issue.record("expected added") }
        if case .duplicate = store.add(rawName: "tomato") {} else { Issue.record("expected duplicate") }
        if case .duplicate = store.add(rawName: "  TOMATO  ") {} else { Issue.record("expected duplicate") }
        #expect(store.ingredients.count == 1)
        #expect(store.ingredients.first?.canonicalName == "tomato")
    }

    @Test func emptyInputIsRejected() {
        let (store, _) = makeStore()
        if case .empty = store.add(rawName: "  \n\t ") {} else { Issue.record("expected empty") }
        #expect(store.ingredients.isEmpty)
    }

    @Test func parseAndAddSplitsAndReportsMixedOutcomes() {
        let (store, _) = makeStore()
        let outcomes = store.parseAndAdd("eggs, ground beef; chicken thigh\nchicken")
        // "chicken thigh" → "chicken"; second "chicken" is duplicate → 3 added, 1 dup
        let added = outcomes.filter { if case .added = $0 { true } else { false } }.count
        let dups = outcomes.filter { if case .duplicate = $0 { true } else { false } }.count
        #expect(added == 3)
        #expect(dups == 1)
        #expect(store.ingredients.map(\.canonicalName).sorted() == ["beef", "chicken", "egg"])
    }

    @Test func removeAndClear() {
        let (store, _) = makeStore()
        store.parseAndAdd("garlic, onion, lemon")
        let onion = store.ingredients.first { $0.canonicalName == "onion" }!
        store.remove(onion.id)
        #expect(store.ingredients.count == 2)
        store.clear()
        #expect(store.ingredients.isEmpty)
    }

    @Test func renameRecanonicalizes() {
        let (store, _) = makeStore()
        store.add(rawName: "Cherry Tomatoes")
        let id = store.ingredients[0].id
        let outcome = store.rename(id, to: "roma tomatoes")
        if case .renamed(let updated) = outcome {
            #expect(updated.name == "roma tomatoes")
            #expect(updated.canonicalName == "tomato")
        } else {
            Issue.record("expected renamed")
        }
    }

    @Test func renameDuplicateIsRejectedNonDestructively() {
        let (store, _) = makeStore()
        store.add(rawName: "tomato")
        store.add(rawName: "garlic")
        let garlicID = store.ingredients.first { $0.canonicalName == "garlic" }!.id
        let outcome = store.rename(garlicID, to: "Cherry Tomatoes")
        if case .wouldDuplicate = outcome {} else { Issue.record("expected wouldDuplicate") }
        // State unchanged
        #expect(store.ingredients.count == 2)
        #expect(store.ingredients.first { $0.id == garlicID }?.canonicalName == "garlic")
    }

    @Test func renameUnchangedIsNoop() {
        let (store, _) = makeStore()
        store.add(rawName: "tomato")
        let id = store.ingredients[0].id
        let outcome = store.rename(id, to: "tomato")
        if case .unchanged = outcome {} else { Issue.record("expected unchanged") }
    }

    @Test func renameMissingIDReportsNotFound() {
        let (store, _) = makeStore()
        let outcome = store.rename(Ingredient.ID(), to: "tomato")
        if case .notFound = outcome {} else { Issue.record("expected notFound") }
    }

    @Test func persisterSeesEachMutation() throws {
        let (store, persister) = makeStore()
        store.add(rawName: "tomato")
        #expect(try persister.load().count == 1)
        store.add(rawName: "garlic")
        #expect(try persister.load().count == 2)
        store.clear()
        #expect(try persister.load().isEmpty)
    }

    @Test func storeRehydratesFromPersister() {
        let seeded = [
            Ingredient(name: "tomato", canonicalName: "tomato", category: .produce),
            Ingredient(name: "garlic", canonicalName: "garlic", category: .produce)
        ]
        let (store, _) = makeStore(initial: seeded)
        #expect(store.ingredients.count == 2)
        #expect(store.canonicalSet == ["tomato", "garlic"])
    }

    @Test func restoreReplacesBoardAtomically() {
        let (store, _) = makeStore()
        store.add(rawName: "tomato")
        let snapshot = store.ingredients
        store.clear()
        #expect(store.ingredients.isEmpty)
        store.restore(snapshot)
        #expect(store.ingredients.count == 1)
        #expect(store.ingredients.first?.canonicalName == "tomato")
    }
}
