import Foundation
import SwiftUI

struct ShoppingProvider: Identifiable, Hashable {
    let id: String
    let name: String
    let brandColor: Color
    let logoSymbol: String
    let logoBackground: Color
    let deliveryEstimate: String
    let deliveryMinutes: Int
    let availableCanonicalKeys: Set<String>
    let unitPrices: [String: Double]
    let priceMultiplier: Double
    let deepLinkScheme: String
    let webFallback: String

    static func == (lhs: ShoppingProvider, rhs: ShoppingProvider) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ShoppingProviderQuote {
    let provider: ShoppingProvider
    let availableItems: [ShoppingItem]
    let missingItems: [ShoppingItem]
    let estimatedTotal: Double

    var availableCount: Int { availableItems.count }
    var totalCount: Int { availableItems.count + missingItems.count }
    var hasAll: Bool { missingItems.isEmpty && totalCount > 0 }

    var availabilityLabel: String {
        if totalCount == 0 { return "Add items to compare" }
        if hasAll { return "All items available" }
        return "\(availableCount) of \(totalCount) items available"
    }

    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: estimatedTotal)) ?? "$0.00"
    }
}

extension ShoppingProvider {
    func quote(for items: [ShoppingItem]) -> ShoppingProviderQuote {
        let active = items.filter { !$0.isChecked }
        var available: [ShoppingItem] = []
        var missing: [ShoppingItem] = []
        var total: Double = 0

        for item in active {
            if availableCanonicalKeys.contains(item.canonicalKey) {
                available.append(item)
                let unit = unitPrices[item.canonicalKey] ?? ShoppingProviderCatalog.fallbackUnitPrice(for: item.canonicalKey)
                total += unit * priceMultiplier * Double(item.quantity)
            } else {
                missing.append(item)
            }
        }

        return ShoppingProviderQuote(
            provider: self,
            availableItems: available,
            missingItems: missing,
            estimatedTotal: total
        )
    }

    func searchURL(for items: [ShoppingItem]) -> URL? {
        let names = items.filter { !$0.isChecked }.map(\.name)
        guard !names.isEmpty else { return nil }
        var components = URLComponents(string: webFallback)
        components?.queryItems = [URLQueryItem(name: "query", value: names.joined(separator: ", "))]
        return components?.url
    }
}

enum ShoppingProviderCatalog {
    static let all: [ShoppingProvider] = [
        ShoppingProvider(
            id: "instacart",
            name: "Instacart",
            brandColor: Color(red: 0.21, green: 0.65, blue: 0.20),
            logoSymbol: "carrot.fill",
            logoBackground: Color(red: 0.94, green: 0.97, blue: 0.92),
            deliveryEstimate: "30-60 min",
            deliveryMinutes: 45,
            availableCanonicalKeys: [
                "tomato", "broccoli", "garlic", "olive oil", "pasta",
                "bell pepper", "sesame oil", "milk", "onion", "egg",
                "parmesan cheese", "basil", "bread"
            ],
            unitPrices: [
                "tomato": 1.20, "broccoli": 2.80, "garlic": 0.90,
                "olive oil": 8.50, "pasta": 2.40, "bell pepper": 1.40,
                "sesame oil": 6.50, "parmesan cheese": 6.99, "basil": 2.50,
                "bread": 3.20, "milk": 3.99, "onion": 0.80, "egg": 4.20
            ],
            priceMultiplier: 1.10,
            deepLinkScheme: "instacart://search",
            webFallback: "https://www.instacart.com/store/search"
        ),
        ShoppingProvider(
            id: "amazon-fresh",
            name: "Amazon Fresh",
            brandColor: Color(red: 0.10, green: 0.42, blue: 0.55),
            logoSymbol: "leaf.fill",
            logoBackground: Color(red: 0.91, green: 0.95, blue: 0.97),
            deliveryEstimate: "2 hr",
            deliveryMinutes: 120,
            availableCanonicalKeys: [
                "tomato", "broccoli", "garlic", "olive oil", "pasta",
                "bell pepper", "milk", "onion", "egg", "parmesan cheese", "bread"
            ],
            unitPrices: [
                "tomato": 1.05, "broccoli": 2.50, "garlic": 0.75,
                "olive oil": 7.80, "pasta": 1.95, "bell pepper": 1.25,
                "parmesan cheese": 5.99, "bread": 2.80, "milk": 3.50,
                "onion": 0.65, "egg": 3.80
            ],
            priceMultiplier: 1.00,
            deepLinkScheme: "amazon://search",
            webFallback: "https://www.amazon.com/alm/storefront"
        ),
        ShoppingProvider(
            id: "walmart",
            name: "Walmart",
            brandColor: Color(red: 0.02, green: 0.45, blue: 0.78),
            logoSymbol: "sparkle",
            logoBackground: Color(red: 1.00, green: 0.95, blue: 0.78),
            deliveryEstimate: "Tomorrow",
            deliveryMinutes: 1440,
            availableCanonicalKeys: [
                "tomato", "broccoli", "garlic", "olive oil", "pasta",
                "bell pepper", "sesame oil", "milk", "onion", "egg",
                "parmesan cheese", "basil", "bread"
            ],
            unitPrices: [
                "tomato": 0.85, "broccoli": 1.98, "garlic": 0.50,
                "olive oil": 6.50, "pasta": 1.25, "bell pepper": 0.99,
                "sesame oil": 4.95, "parmesan cheese": 4.50, "basil": 1.99,
                "bread": 2.20, "milk": 2.85, "onion": 0.50, "egg": 3.10
            ],
            priceMultiplier: 0.92,
            deepLinkScheme: "walmart://search",
            webFallback: "https://www.walmart.com/search"
        ),
        ShoppingProvider(
            id: "whole-foods",
            name: "Whole Foods",
            brandColor: Color(red: 0.20, green: 0.40, blue: 0.20),
            logoSymbol: "leaf.circle.fill",
            logoBackground: Color(red: 0.92, green: 0.96, blue: 0.90),
            deliveryEstimate: "1-2 hr",
            deliveryMinutes: 90,
            availableCanonicalKeys: [
                "tomato", "broccoli", "garlic", "olive oil",
                "bell pepper", "milk", "onion", "egg", "basil", "bread"
            ],
            unitPrices: [
                "tomato": 1.60, "broccoli": 3.20, "garlic": 1.10,
                "olive oil": 11.50, "bell pepper": 1.80,
                "basil": 3.50, "bread": 4.50, "milk": 4.50,
                "onion": 1.10, "egg": 5.40
            ],
            priceMultiplier: 1.20,
            deepLinkScheme: "wholefoods://search",
            webFallback: "https://www.amazon.com/wholefoodsmarket"
        )
    ]

    static func fallbackUnitPrice(for canonicalKey: String) -> Double {
        switch canonicalKey {
        case "tomato", "garlic", "onion": return 1.00
        case "broccoli", "bell pepper": return 2.00
        case "olive oil", "sesame oil", "parmesan cheese": return 6.00
        case "pasta", "bread": return 2.50
        case "milk", "egg": return 3.50
        default: return 2.00
        }
    }

    static func quotes(for items: [ShoppingItem]) -> [ShoppingProviderQuote] {
        all.map { $0.quote(for: items) }
    }

    static func recommendations(for items: [ShoppingItem]) -> [SmartRecommendationCue] {
        let active = items.filter { !$0.isChecked }
        guard !active.isEmpty else { return [] }
        let allQuotes = quotes(for: items)
        var cues: [SmartRecommendationCue] = []

        let withEverything = allQuotes.filter(\.hasAll)
        if let fastestComplete = withEverything.min(by: { $0.provider.deliveryMinutes < $1.provider.deliveryMinutes }) {
            cues.append(
                .init(
                    label: "All items, fastest",
                    detail: "\(fastestComplete.provider.name) — \(fastestComplete.provider.deliveryEstimate)",
                    providerId: fastestComplete.provider.id
                )
            )
        } else if let bestCoverage = allQuotes.max(by: { $0.availableCount < $1.availableCount }), bestCoverage.availableCount > 0 {
            cues.append(
                .init(
                    label: "Best coverage",
                    detail: "\(bestCoverage.provider.name) — \(bestCoverage.availableCount) of \(bestCoverage.totalCount) items",
                    providerId: bestCoverage.provider.id
                )
            )
        }

        let priceEligible = withEverything.isEmpty ? allQuotes.filter { $0.availableCount > 0 } : withEverything
        if let cheapest = priceEligible.min(by: { $0.estimatedTotal < $1.estimatedTotal }), cheapest.estimatedTotal > 0,
           cheapest.provider.id != cues.first?.providerId {
            cues.append(
                .init(
                    label: "Lowest price",
                    detail: "\(cheapest.provider.name) — \(cheapest.formattedTotal)",
                    providerId: cheapest.provider.id
                )
            )
        }

        return cues
    }
}

struct SmartRecommendationCue: Identifiable, Hashable {
    var id: String { providerId + label }
    let label: String
    let detail: String
    let providerId: String
}
