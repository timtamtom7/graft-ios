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
