import Foundation
import SwiftUI

/// Corner radius tokens for Graft — centralize all corner radius values
enum CornerRadii {
    /// 8pt — small elements, icon backgrounds, small chips
    static let small: CGFloat = 8

    /// 12pt — buttons, medium cards, input fields
    static let button: CGFloat = 12

    /// 14pt — list rows, inactive skill cards
    static let medium: CGFloat = 14

    /// 16pt — liquid glass cards, main content cards
    static let card: CGFloat = 16

    /// 20pt — large modals, sheet backgrounds
    static let large: CGFloat = 20

    /// 24pt — very large rounded elements
    static let extraLarge: CGFloat = 24

    // MARK: - Convenience

    /// Standard week dot corner radius
    static let dot: CGFloat = 7

    /// Pill/capsule shape — use `.capsule` in SwiftUI instead
    @available(*, deprecated, message: "Use SwiftUI's .capsule() modifier instead")
    static let pill: CGFloat = 999
}
