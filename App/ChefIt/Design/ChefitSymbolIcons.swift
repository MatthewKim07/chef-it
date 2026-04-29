import SwiftUI

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
