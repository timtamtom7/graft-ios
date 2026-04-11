import Foundation
import SwiftUI

/// Spacing tokens for Graft — centralize all layout spacing values
enum Spacing {
    /// 4pt — minimum spacing, tight gaps
    static let xs: CGFloat = 4

    /// 8pt — small spacing, icon gaps
    static let sm: CGFloat = 8

    /// 16pt — default spacing, standard padding
    static let md: CGFloat = 16

    /// 24pt — large spacing, section gaps
    static let lg: CGFloat = 24

    /// 32pt — extra large, major section separation
    static let xl: CGFloat = 32

    /// 40pt — maximum spacing, screen margins
    static let xxl: CGFloat = 40

    // MARK: - Convenience

    /// Standard dot size for week progress indicators
    static let dotSize: CGFloat = 14

    /// Standard corner radius for week dots
    static let dotCornerRadius: CGFloat = 7

    /// Standard icon button size
    static let iconButton: CGFloat = 44
}
