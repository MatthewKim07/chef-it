import SwiftUI

enum ChefitColors {
    static let sageGreen = Color(hex: 0x4C5A3E)
    static let matcha = Color(hex: 0xA8C5A1)
    static let pistachio = Color(hex: 0xE8F0E3)
    static let cream = Color(hex: 0xFFF7E8)
    static let peach = Color(hex: 0xFFB79D)
    static let honey = Color(hex: 0xFFD26F)
    static let text = Color(hex: 0x2F3A2E)
    static let white = Color.white
}

enum ChefitSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let twoXL: CGFloat = 48
}

enum ChefitRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let full: CGFloat = 9999
}

enum ChefitTypography {
    static func h1() -> Font { .custom("PlayfairDisplay-Bold", size: 28) }
    static func h2() -> Font { .custom("PlayfairDisplay-Bold", size: 22) }
    static func h3() -> Font { .custom("PlayfairDisplay-Regular", size: 18) }
    static func body() -> Font { .custom("Nunito-Regular", size: 15) }
    static func label() -> Font { .custom("Nunito-SemiBold", size: 13) }
    static func micro() -> Font { .custom("Nunito-Regular", size: 11) }
    static func button() -> Font { .custom("Nunito-Bold", size: 15) }
}

enum ChefitShadows {
    static var card: ShadowStyle {
        ShadowStyle(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    static var nav: ShadowStyle {
        ShadowStyle(color: Color.black.opacity(0.06), radius: 12, x: 0, y: -1)
    }

    static var button: ShadowStyle {
        ShadowStyle(color: Color(red: 1, green: 183 / 255, blue: 157 / 255).opacity(0.35), radius: 12, x: 0, y: 4)
    }
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func chefitCardShadow() -> some View {
        shadow(
            color: ChefitShadows.card.color,
            radius: ChefitShadows.card.radius,
            x: ChefitShadows.card.x,
            y: ChefitShadows.card.y
        )
    }

    func chefitNavShadow() -> some View {
        shadow(
            color: ChefitShadows.nav.color,
            radius: ChefitShadows.nav.radius,
            x: ChefitShadows.nav.x,
            y: ChefitShadows.nav.y
        )
    }

    func chefitPrimaryButtonShadow() -> some View {
        shadow(
            color: ChefitShadows.button.color,
            radius: ChefitShadows.button.radius,
            x: ChefitShadows.button.x,
            y: ChefitShadows.button.y
        )
    }
}

private extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
