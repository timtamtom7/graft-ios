import SwiftUI

// MARK: - iOS 26 Liquid Glass Design System

enum Theme {
    // MARK: - Corner Radius Tokens
    enum CornerRadius {
        static let xs: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 9999
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 10
        static let md: CGFloat = 12
        static let lg: CGFloat = 14
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 20
        static let xxxl: CGFloat = 24
        static let huge: CGFloat = 32
        static let giant: CGFloat = 40
    }

    // MARK: - Font Sizes (iOS 26 minimum 11pt)
    enum FontSize {
        static let caption2: CGFloat = 11
        static let caption: CGFloat = 12
        static let footnote: CGFloat = 13
        static let subheadline: CGFloat = 15
        static let headline: CGFloat = 17
        static let title3: CGFloat = 20
        static let title2: CGFloat = 22
        static let title: CGFloat = 24
        static let largeTitle: CGFloat = 28
        static let giant: CGFloat = 36
    }

    // MARK: - Shadows
    enum Shadow {
        static let small = (color: Color.black.opacity(0.1), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let medium = (color: Color.black.opacity(0.15), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let large = (color: Color.black.opacity(0.2), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
        static let glow = (color: GraftColors.accent.opacity(0.3), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(0))
    }

    // MARK: - Animation
    enum Animation {
        static let quick: SwiftUI.Animation = .easeInOut(duration: 0.15)
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.25)
        static let slow: SwiftUI.Animation = .easeInOut(duration: 0.35)
        static let spring: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.7)
    }

    // MARK: - Icon Sizes
    enum IconSize {
        static let small: CGFloat = 12
        static let medium: CGFloat = 14
        static let large: CGFloat = 18
        static let xlarge: CGFloat = 22
        static let xxlarge: CGFloat = 28
        static let giant: CGFloat = 36
        static let huge: CGFloat = 44
    }
}

// MARK: - Haptic Feedback

enum HapticFeedback {
    static func light() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }

    static func medium() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }

    static func heavy() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        #endif
    }

    static func soft() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
        #endif
    }

    static func rigid() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
        #endif
    }

    static func success() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    static func warning() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        #endif
    }

    static func error() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        #endif
    }

    static func selection() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }
}

// MARK: - Button Styles

struct GraftPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: Theme.FontSize.subheadline, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xl)
            .background(
                LinearGradient(
                    colors: isEnabled
                        ? [GraftColors.accent, GraftColors.accentMuted]
                        : [GraftColors.surfaceRaised, GraftColors.surfaceRaised],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}

struct GraftSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: Theme.FontSize.subheadline, weight: .medium))
            .foregroundColor(isEnabled ? GraftColors.accent : GraftColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xl)
            .background(GraftColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .strokeBorder(isEnabled ? GraftColors.accent.opacity(0.3) : GraftColors.surfaceRaised, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}

struct GraftIconButtonStyle: ButtonStyle {
    let size: CGFloat

    init(size: CGFloat = 44) {
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: Theme.IconSize.large))
            .foregroundColor(GraftColors.accent)
            .frame(width: size, height: size)
            .background(configuration.isPressed ? GraftColors.surfaceRaised : Color.clear)
            .clipShape(Circle())
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}

struct GraftPillButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: Theme.FontSize.footnote, weight: .medium))
            .foregroundColor(isSelected ? .white : GraftColors.textSecondary)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                isSelected
                    ? LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [GraftColors.surface], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}

struct GraftCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(Theme.Animation.spring, value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func graftCardStyle() -> some View {
        self
            .background(GraftColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .strokeBorder(GraftColors.accent.opacity(0.2), lineWidth: 1)
            )
    }

    func graftGlassCardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.12),
                                        Color.white.opacity(0.05),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xl))
    }

    func graftSectionLabel() -> some View {
        self
            .font(.system(size: Theme.FontSize.caption2, weight: .medium))
            .foregroundColor(GraftColors.textSecondary)
            .textCase(.uppercase)
            .tracking(1.2)
    }
}

// MARK: - Text Extensions

extension Text {
    func graftLabel() -> some View {
        self
            .font(.system(size: Theme.FontSize.caption2, weight: .medium))
            .foregroundColor(GraftColors.textSecondary)
            .textCase(.uppercase)
            .tracking(1.2)
    }
}
