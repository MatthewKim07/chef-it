import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

public enum BrandColor {
    public static let sageGreen  = Color(hex: "#4C5A3E")
    public static let matcha     = Color(hex: "#A8C5A1")
    public static let pistachio  = Color(hex: "#E8F0E3")
    public static let cream      = Color(hex: "#FFFBF7")
    public static let peach      = Color(hex: "#FFB79D")
    public static let honey      = Color(hex: "#FFD26F")
    public static let text       = Color(hex: "#2F3A2E")
}
