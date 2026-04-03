import SwiftUI

extension Color {

    static let cardBackground = Color("CardBackground", bundle: nil)
    static let primaryText = Color("PrimaryText", bundle: nil)
    static let secondaryText = Color("SecondaryText", bundle: nil)
    static let accentBrand = Color("AccentBrand", bundle: nil)
    static let surfaceBackground = Color("SurfaceBackground", bundle: nil)

    static let userBubble = Color("UserBubble", bundle: nil)
    static let assistantBubble = Color("AssistantBubble", bundle: nil)
}

extension Color {

    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch trimmed.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
