import Foundation

struct ShoppingItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var quantity: Int
    var isChecked: Bool
    var category: String?
    /// Matches `IngredientNormalizer.canonicalize` output for merge/dedup.
    var canonicalKey: String

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Int = 1,
        isChecked: Bool = false,
        category: String?,
        canonicalKey: String
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.isChecked = isChecked
        self.category = category
        self.canonicalKey = canonicalKey
    }
}
