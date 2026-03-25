import SwiftUI

// MARK: - Empty State

struct EmptyStateView: View {
    let skillName: String
    let onLogSession: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Custom hourglass composition
            HourglassGraphic(size: 80)
                .frame(width: 80, height: 80)

            Text("No sessions yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(GraftColors.textPrimary)

            Text("Your first session with \(skillName) starts the clock.")
                .font(.system(size: 14))
                .foregroundColor(GraftColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            Button {
                onLogSession()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Log First Session")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [GraftColors.accent, GraftColors.accentMuted],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 48)
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GraftColors.background)
    }
}

// MARK: - Skill Limit Reached

struct SkillLimitView: View {
    let onUpgrade: () -> Void
    let onChangeSkill: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Limit icon
            ZStack {
                Circle()
                    .fill(GraftColors.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "lock.fill")
                    .font(.system(size: 36))
                    .foregroundColor(GraftColors.accent)
            }

            VStack(spacing: 8) {
                Text("Skill limit reached")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(GraftColors.textPrimary)

                Text("You're on the Free plan with access to 1 skill. Upgrade to Track or Master to add more skills.")
                    .font(.system(size: 14))
                    .foregroundColor(GraftColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Button {
                    onUpgrade()
                } label: {
                    Text("Upgrade Plan")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [GraftColors.accent, GraftColors.accentMuted],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    onChangeSkill()
                } label: {
                    Text("Change Skill Instead")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(GraftColors.textSecondary)
                }
            }
            .padding(.horizontal, 48)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GraftColors.background)
    }
}

// MARK: - Session Logging Failed

struct SessionErrorView: View {
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(GraftColors.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(GraftColors.accent)
            }

            VStack(spacing: 8) {
                Text("Session not saved")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(GraftColors.textPrimary)

                Text(message.isEmpty
                     ? "Something went wrong saving your session. Please try again."
                     : message)
                    .font(.system(size: 14))
                    .foregroundColor(GraftColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Button {
                    onRetry()
                } label: {
                    Text("Try Again")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [GraftColors.accent, GraftColors.accentMuted],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    onDismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(GraftColors.textSecondary)
                }
            }
            .padding(.horizontal, 48)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GraftColors.background)
    }
}

// MARK: - Custom Graphics

struct HourglassGraphic: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Top bulb
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            GraftColors.accent.opacity(0.3),
                            GraftColors.accent.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.5, height: size * 0.3)
                .position(x: size * 0.5, y: size * 0.15)

            // Bottom bulb
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            GraftColors.accent.opacity(0.1),
                            GraftColors.accent.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.5, height: size * 0.3)
                .position(x: size * 0.5, y: size * 0.85)

            // Sand stream
            Rectangle()
                .fill(GraftColors.accent.opacity(0.6))
                .frame(width: 2, height: size * 0.4)
                .position(x: size * 0.5, y: size * 0.5)

            // Frame
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(GraftColors.accent.opacity(0.5), lineWidth: 2)
                .frame(width: size * 0.55, height: size * 0.85)

            // Top cap
            Capsule()
                .fill(GraftColors.surfaceRaised)
                .frame(width: size * 0.65, height: size * 0.08)
                .position(x: size * 0.5, y: size * 0.06)

            // Bottom cap
            Capsule()
                .fill(GraftColors.surfaceRaised)
                .frame(width: size * 0.65, height: size * 0.08)
                .position(x: size * 0.5, y: size * 0.94)
        }
        .frame(width: size, height: size)
    }
}

struct SkillIconGraphic: View {
    let skill: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            GraftColors.accent.opacity(0.2),
                            GraftColors.accent.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Image(systemName: iconFor(skill))
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(GraftColors.accent)
        }
    }

    private func iconFor(_ skill: String) -> String {
        switch skill.lowercased() {
        case "guitar": return "guitars"
        case "piano": return "pianokeys"
        case "coding", "code": return "chevron.left.forwardslash.chevron.right"
        case "language": return "text.bubble"
        case "chess": return "figure.chess"
        case "drawing": return "paintbrush"
        case "basketball": return "basketball"
        case "tennis": return "tennis.racket"
        case "running": return "figure.run"
        case "reading": return "book"
        case "writing": return "pencil"
        case "cooking": return "frying.pan"
        case "photography": return "camera"
        case "yoga": return "figure.yoga"
        case "singing": return "music.mic"
        case "drums": return "drum"
        case "woodworking": return "hammer"
        case "gardening": return "leaf"
        case "calligraphy": return "pen.nib"
        case "meditation": return "brain.head.profile"
        default: return "star.fill"
        }
    }
}

struct ProgressBarGraphic: View {
    let progress: Double
    let height: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(GraftColors.surfaceRaised)
                    .frame(height: height)

                // Fill
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [GraftColors.accent, GraftColors.accentMuted],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geometry.size.width * CGFloat(min(progress, 1.0))), height: height)

                // Glow
                if progress > 0 {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(GraftColors.accent)
                        .frame(width: geometry.size.width * CGFloat(min(progress, 1.0)), height: height)
                        .blur(radius: 4)
                        .opacity(0.4)
                }
            }
        }
        .frame(height: height)
    }
}

// MARK: - Streak Badge (R6)

struct StreakBadge: View {
    let streakDays: Int
    let size: BadgeSize

    enum BadgeSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 20
            case .large: return 28
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 11
            case .medium: return 14
            case .large: return 20
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 10
            case .large: return 14
            }
        }

        var fireSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 24
            }
        }
    }

    var body: some View {
        HStack(spacing: size.padding * 0.4) {
            Text("🔥")
                .font(.system(size: size.fireSize))

            Text("\(streakDays)")
                .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                .foregroundColor(streakColor)

            if size != .small {
                Text(dayLabel)
                    .font(.system(size: size.fontSize - 2))
                    .foregroundColor(GraftColors.textSecondary)
            }
        }
        .padding(.horizontal, size.padding)
        .padding(.vertical, size.padding * 0.7)
        .background(
            RoundedRectangle(cornerRadius: size.padding * 1.2)
                .fill(badgeGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: size.padding * 1.2)
                .strokeBorder(strokeColor.opacity(0.4), lineWidth: 1)
        )
    }

    private var streakColor: Color {
        if streakDays >= 30 {
            return Color(hex: "f59e0b") // gold
        } else if streakDays >= 7 {
            return Color(hex: "e879f9") // purple
        } else {
            return GraftColors.accent
        }
    }

    private var badgeGradient: LinearGradient {
        let base = streakColor.opacity(0.15)
        return LinearGradient(
            colors: [base, base.opacity(0.05)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var strokeColor: Color {
        streakColor.opacity(0.5)
    }

    private var dayLabel: String {
        streakDays == 1 ? "day" : "days"
    }
}

// MARK: - Timer Mockup View (R6)

struct TimerMockupView: View {
    let duration: Int // minutes
    let elapsed: Int // seconds
    let skillEmoji: String
    let skillName: String
    let isRunning: Bool

    private let size: CGFloat = 200

    private var progress: Double {
        guard duration > 0 else { return 0 }
        return min(Double(elapsed) / Double(duration * 60), 1.0)
    }

    private var remainingSeconds: Int {
        max((duration * 60) - elapsed, 0)
    }

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(GraftColors.accent.opacity(0.08))
                .frame(width: size + 30, height: size + 30)

            // Track circle
            Circle()
                .stroke(GraftColors.surfaceRaised, lineWidth: 10)
                .frame(width: size, height: size)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [GraftColors.accent, GraftColors.accentMuted],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 8) {
                if isRunning {
                    // Pulsing indicator
                    Circle()
                        .fill(GraftColors.accent)
                        .frame(width: 8, height: 8)
                        .opacity(pulsingOpacity)
                        .animation(
                            isRunning ?
                                Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                                .default,
                            value: isRunning
                        )
                }

                Text(formattedTime)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(isRunning ? GraftColors.textPrimary : GraftColors.textSecondary)

                HStack(spacing: 4) {
                    Text(skillEmoji)
                        .font(.system(size: 14))
                    Text(skillName)
                        .font(.system(size: 12))
                        .foregroundColor(GraftColors.textSecondary)
                }
            }
        }
    }

    private var pulsingOpacity: Double {
        isRunning ? 1.0 : 0.3
    }
}

// MARK: - App Icon Renderer (R6)

import SwiftUI
import UIKit

struct AppIconRenderer {
    static func render(size: CGSize = CGSize(width: 1024, height: 1024)) -> UIImage {
        let view = AppIconView()
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let swiftuiView = view
            let controller = UIHostingController(rootView: swiftuiView)
            controller.view.backgroundColor = .clear
            controller.view.frame = CGRect(origin: .zero, size: size)
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "0d0d14")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Glowing accent circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "e879f9").opacity(0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 600, height: 600)

            // Main icon - stylized hourglass / flame
            VStack(spacing: 8) {
                ZStack {
                    // Outer ring
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color(hex: "e879f9"), Color(hex: "e879f9").opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 24
                        )
                        .frame(width: 360, height: 360)

                    // Inner fill
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "1e1e24"), Color(hex: "141417")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 312, height: 312)

                    // Flame-like shape
                    VStack(spacing: 0) {
                        Text("🔥")
                            .font(.system(size: 140))
                            .shadow(color: Color(hex: "e879f9").opacity(0.5), radius: 20)
                    }
                }
            }

            // Top highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.15), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -200, y: -200)
        }
        .frame(width: 1024, height: 1024)
    }
}
