import SwiftUI
import ChefItKit
#if canImport(UIKit)
import UIKit
#endif

/// SF Symbol names used across the app. Swap strings here when you add matching assets to Assets.xcassets
/// and render them with ``ChefitIcon`` `.asset(...)`.
enum ChefitSymbol {

    // Splash / brand
    static let splashHero = "fork.knife.circle.fill"

    // Categories (Browse)
    static let quickEasy = "bolt.fill"
    static let vegetarian = "leaf.fill"
    static let dinner = "fork.knife"
    static let breakfast = "sunrise.fill"

    // Ingredients & pantry (semantic defaults)
    static let tomato = "carrot.fill"
    static let garlic = "sparkles"
    static let oliveOil = "drop.fill"
    static let pasta = "takeoutbag.and.cup.and.straw.fill"
    static let milk = "cup.and.saucer.fill"
    static let onion = "circle.hexagongrid.circle.fill"
    static let broccoli = "leaf.circle.fill"
    static let chicken = "bird.fill"
    static let egg = "oval.fill"
    static let avocado = "circle.circle.fill"
    /// Decorative (e.g. splash strip)
    static let chili = "sun.max.fill"

    // Recipe / meta
    static let noodleBowl = "takeoutbag.and.cup.and.straw.fill"
    static let clock = "clock.fill"
    static let star = "star.fill"
    static let personServings = "person.fill"

    // Steps (recipe flow)
    static let stepBoilPasta = "takeoutbag.and.cup.and.straw.fill"
    static let stepSaute = "flame.fill"
    static let stepTomatoes = "carrot.fill"
    static let stepServe = "fork.knife.circle"

    static let sprout = "leaf.circle.fill"

    // Social
    static let heart = "heart.fill"
    static let comment = "bubble.left.fill"
    static let bookmark = "bookmark.fill"
}

/// Vector SF Symbol or optional raster/SVG from your asset catalog.
enum ChefitIconSource {
    case system(String)
    /// Image set name in Assets.xcassets (add PNG/PDF/SVG there).
    case asset(String)
}

struct ChefitIcon: View {
    let source: ChefitIconSource
    var size: CGFloat = 22
    var weight: Font.Weight = .medium

    var body: some View {
        switch source {
        case .system(let name):
            Image(systemName: name)
                .font(.system(size: size, weight: weight))
                .symbolRenderingMode(.hierarchical)
        case .asset(let name):
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }
}

enum IngredientIconResolver {
    private static let fallbackByCategory: [IngredientCategory: String] = [
        .produce: "carrot.fill",
        .protein: "fish.fill",
        .dairy: "cup.and.saucer.fill",
        .pantry: "cabinet.fill",
        .spice: "sparkles",
        .grain: "leaf.fill",
        .condiment: "drop.fill",
        .other: "fork.knife"
    ]

    static func fallbackSymbol(for category: IngredientCategory) -> String {
        fallbackByCategory[category] ?? "fork.knife"
    }

    static func iconName(for ingredient: String) -> String {
        let key = normalized(ingredient)
        if let alias = aliasByCanonical[key] {
            if imageExists(named: alias) { return alias }
        }
        if let alias = bestAliasMatch(in: key) {
            if imageExists(named: alias) { return alias }
        }
        for token in key.split(separator: " ").map(String.init) {
            if let alias = aliasByCanonical[token], imageExists(named: alias) {
                return alias
            }
            if imageExists(named: token) { return token }
        }
        for variant in filenameVariants(for: ingredient) {
            if imageExists(named: variant) { return variant }
        }
        return ""
    }

    #if canImport(UIKit)
    static func image(for ingredient: String) -> UIImage? {
        let iconName = iconName(for: ingredient)
        guard !iconName.isEmpty else { return nil }
        if let fileURL = resolveBundleURL(for: iconName) {
            return UIImage(contentsOfFile: fileURL.path)
        }
        if let image = UIImage(named: iconName) { return image }
        if let image = UIImage(named: "\(iconName).png") { return image }
        return nil
    }
    #endif

    private static func filenameVariants(for ingredient: String) -> [String] {
        let lowered = normalized(ingredient)
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
        let cleaned = lowered
            .components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted)
            .joined(separator: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return [] }

        var options = Set<String>()
        options.insert(cleaned)
        if cleaned.hasSuffix("es"), cleaned.count > 3 {
            options.insert(String(cleaned.dropLast(2)))
        }
        if cleaned.hasSuffix("s"), cleaned.count > 2 {
            options.insert(String(cleaned.dropLast()))
        }

        var variants = Set<String>()
        for option in options {
            let words = option.split(separator: " ").map(String.init)
            guard !words.isEmpty else { continue }

            // Match lowercase snake_case files in ingredients_icons/
            variants.insert(words.joined(separator: "_").lowercased())

            // Match Title_Case files in ingredient_icons_transparent/
            let title = words
                .map { word in
                    let lower = word.lowercased()
                    return lower.prefix(1).uppercased() + lower.dropFirst()
                }
                .joined(separator: "_")
            variants.insert(title)
        }
        return Array(variants)
    }

    private static func imageExists(named iconName: String) -> Bool {
        #if canImport(UIKit)
        if UIImage(named: iconName) != nil { return true }
        if UIImage(named: "\(iconName).png") != nil { return true }
        return resolveBundleURL(for: iconName) != nil
        #else
        return false
        #endif
    }

    private static func resolveBundleURL(for iconName: String) -> URL? {
        let lower = iconName.lowercased()
        if let exact = resourceURLByLowerName[lower] {
            return exact
        }
        if let ext = resourceURLByLowerName["\(lower).png"] {
            return ext
        }
        return nil
    }

    private static let resourceURLByLowerName: [String: URL] = {
        var map: [String: URL] = [:]
        guard let resourceURL = Bundle.main.resourceURL else { return map }
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: resourceURL, includingPropertiesForKeys: [.isRegularFileKey]) else {
            return map
        }
        for case let url as URL in enumerator {
            if url.pathExtension.lowercased() == "png" {
                let basename = url.deletingPathExtension().lastPathComponent.lowercased()
                map[basename] = url
                map[url.lastPathComponent.lowercased()] = url
            }
        }
        return map
    }()

    private static func normalized(_ ingredient: String) -> String {
        ingredient
            .lowercased()
            .replacingOccurrences(of: "&", with: " and ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let aliasByCanonical: [String: String] = [
        "beef": "red_meat",
        "chicken": "chicken_breast",
        "egg": "eggs",
        "turmeric": "turmeric",
        "turmeric root": "turmeric",
        "almond": "almond",
        "almonds": "almond",
        "apple": "apple",
        "green apple": "apple",
        "red apple": "apple",
        "quinoa": "quinoa",
        "red lentil": "redlentils",
        "red lentils": "redlentils",
        "hazelnut": "hazelnut",
        "hazelnuts": "hazelnut",
        "walnut": "walnut",
        "walnuts": "walnut",
        "spinach leaf": "spinach_leaves",
        "spinach leaves": "spinach_leaves",
        "blueberry": "blueberries",
        "blueberries": "blueberries",
        "pea": "green_peas",
        "peas": "green_peas",
        "lentil": "lentils_bowl",
        "lentils": "lentils_bowl",
        "rice": "brown_rice",
        "grapefruit": "grapefruit",
        "black eyed peas": "black_eyed_peas"
    ]

    private static func bestAliasMatch(in key: String) -> String? {
        let pairs = aliasByCanonical.sorted { $0.key.count > $1.key.count }
        for (aliasKey, assetName) in pairs where key.contains(aliasKey) {
            return assetName
        }
        return nil
    }
}

struct IngredientIconView: View {
    let ingredientName: String
    let category: IngredientCategory
    var size: CGFloat = 36

    private var iconName: String {
        IngredientIconResolver.iconName(for: ingredientName)
    }

    private var iconScale: CGFloat {
        switch iconName.lowercased() {
        case "lentils_bowl", "redlentils":
            return 0.88
        default:
            return 1.0
        }
    }

    private var iconOffset: CGSize {
        switch iconName.lowercased() {
        case "pomegranate":
            return CGSize(width: -2, height: 0)
        default:
            return .zero
        }
    }

    var body: some View {
        Group {
            #if canImport(UIKit)
            if let image = IngredientIconResolver.image(for: ingredientName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(iconScale)
                    .offset(iconOffset)
            } else {
                ZStack {
                    Circle()
                        .fill(ChefitColors.pistachio.opacity(0.8))
                    Image(systemName: IngredientIconResolver.fallbackSymbol(for: category))
                        .font(.system(size: size * 0.42, weight: .semibold))
                        .foregroundStyle(ChefitColors.sageGreen)
                }
            }
            #else
            Image(systemName: IngredientIconResolver.fallbackSymbol(for: category))
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(ChefitColors.sageGreen)
            #endif
        }
        .frame(width: size, height: size)
    }
}
