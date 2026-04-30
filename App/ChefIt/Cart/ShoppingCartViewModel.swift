import ChefItKit
import Foundation
import SwiftUI
import UIKit

@MainActor
final class ShoppingCartViewModel: ObservableObject {
    @Published private(set) var items: [ShoppingItem] = []

    private let defaults: UserDefaults
    private let key = "ChefIt.ShoppingCart.v1"
    private let normalizer = IngredientNormalizer()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func loadFromRecipe(recipeId: String, pantryCanonical: Set<String>) {
        let names = ChefitSampleData.ingredientDisplayNames(forRecipeId: recipeId)
        let missing = ShoppingListBuilder.missingIngredientDisplayNames(
            recipeIngredientNames: names,
            pantryCanonical: pantryCanonical,
            normalizer: normalizer
        )
        let built = ShoppingListBuilder.buildShoppingItems(from: missing, normalizer: normalizer)
        merge(built)
        persist()
    }

    func toggleItem(_ item: ShoppingItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        var row = items[i]
        row.isChecked.toggle()
        items[i] = row
        persist()
    }

    func updateQuantity(_ item: ShoppingItem, delta: Int) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        let next = items[i].quantity + delta
        if next < 1 {
            items.remove(at: i)
        } else {
            var row = items[i]
            row.quantity = next
            items[i] = row
        }
        persist()
    }

    func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    func openInstacart() {
        guard let url = ShoppingListBuilder.instacartSearchURL(items: items) else { return }
        UIApplication.shared.open(url)
    }

    private func merge(_ incoming: [ShoppingItem]) {
        var copy = items
        for item in incoming {
            if let i = copy.firstIndex(where: { $0.canonicalKey == item.canonicalKey }) {
                var row = copy[i]
                row.quantity += item.quantity
                copy[i] = row
            } else {
                copy.append(item)
            }
        }
        items = copy
    }

    private func load() {
        guard let data = defaults.data(forKey: key) else { return }
        if let decoded = try? JSONDecoder().decode([ShoppingItem].self, from: data) {
            items = decoded
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: key)
    }
}
