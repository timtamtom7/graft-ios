import SwiftUI

enum GraftColors {
    // MARK: - Base
    static let background = Color(hex: "0d0d0e")
    static let surface = Color(hex: "161618")
    static let surfaceRaised = Color(hex: "1e1e21")
    static let accent = Color(hex: "e879f9")
    static let accentMuted = Color(hex: "a855f7")

    // MARK: - Text
    static let textPrimary = Color(hex: "f4f4f5")
    static let textSecondary = Color(hex: "a1a1aa")
    static let textOnAccent = Color.white  // for text rendered on accent-colored surfaces

    // MARK: - Semantic
    static let success = Color(hex: "4ade80")
    static let amber = Color(hex: "f59e0b")
    static let streakOrange = Color.orange  // for streak flame icons

    // MARK: - Flow State Gradient
    static let flowStateGradientStart = Color(hex: "7C3AED")
    static let flowStateGradientEnd = Color(hex: "4F46E5")

    // MARK: - Rank Colors
    static let gold = Color(hex: "ffd700")
    static let silver = Color(hex: "c0c0c0")
    static let bronze = Color(hex: "cd7f32")

    // MARK: - Trend Colors
    static let upTrend = Color(hex: "4ade80")
    static let downTrend = Color(hex: "f87171")

    // MARK: - Avatar Colors
    static let avatarGuitar = Color(hex: "f97316")
    static let avatarPiano = Color(hex: "3b82f6")
    static let avatarCoding = Color(hex: "8b5cf6")
    static let avatarDrums = Color(hex: "ef4444")
    static let avatarVocals = Color(hex: "ec4899")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
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
