import SwiftUI

struct MacAISuggestionsView: View {
    let skills: [Skill]

    @State private var suggestion: SessionSuggestion?
    @State private var practiceTip: String = ""
    @State private var isStreakAtRisk: Bool = false
    @State private var isLoading: Bool = true

    var body: some View {
        VStack(spacing: 16) {
            coachHeader

            if isLoading {
                loadingView
            } else {
                VStack(spacing: 12) {
                    if let suggestion = suggestion {
                        sessionSuggestionCard(suggestion)
                    }
                    if isStreakAtRisk {
                        streakWarningCard
                    }
                    if !practiceTip.isEmpty {
                        practiceTipCard
                    }
                }
            }
        }
        .padding(20)
        .background(GraftColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear { loadSuggestions() }
    }

    // MARK: - Header

    private var coachHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(GraftColors.accent)
                .frame(width: 36, height: 36)
                .background(GraftColors.accent.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Your AI Coach")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(GraftColors.textPrimary)
                Text("Adaptive session recommendations")
                    .font(.system(size: 12))
                    .foregroundColor(GraftColors.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(GraftColors.accent)
            Spacer()
        }
        .padding(.vertical, 24)
    }

    // MARK: - Session Suggestion Card

    private func sessionSuggestionCard(_ suggestion: SessionSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(GraftColors.accent)
                Text("Your AI coach suggests...")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.0)
                Spacer()
            }

            // Skill emoji
            if let skill = suggestedSkill {
                HStack(spacing: 12) {
                    Text(skill.emoji)
                        .font(.system(size: 28))
                        .frame(width: 48, height: 48)
                        .background(GraftColors.accent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(skill.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(GraftColors.textPrimary)

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text(suggestion.formattedDuration)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                            Text("·")
                                .font(.system(size: 12))
                            Text(suggestion.focusArea)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(GraftColors.accent)
                    }

                    Spacer()
                }
            }

            // Reason
            Text(suggestion.reason)
                .font(.system(size: 13))
                .foregroundColor(GraftColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GraftColors.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Warmup hint
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 11))
                    .foregroundColor(GraftColors.amber)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Warmup")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(GraftColors.textSecondary)
                    Text(suggestion.warmup)
                        .font(.system(size: 12))
                        .foregroundColor(GraftColors.textSecondary.opacity(0.8))
                }

                Spacer()
            }
        }
        .padding(14)
        .background(GraftColors.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Streak Warning Card

    private var streakWarningCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 16))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Streak at Risk!")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(GraftColors.textPrimary)
                Text("Practice today to keep your streak alive.")
                    .font(.system(size: 12))
                    .foregroundColor(GraftColors.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Practice Tip Card

    private var practiceTipCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(GraftColors.amber)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text("Tip of the Day")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(GraftColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(practiceTip)
                    .font(.system(size: 13))
                    .foregroundColor(GraftColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(GraftColors.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Data Loading

    private var suggestedSkill: Skill? {
        skills.first { $0.isActive }
    }

    private func loadSuggestions() {
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let coach = AICoachService.shared

            if let skill = suggestedSkill {
                let allSessions = DatabaseService.shared.getAllSessions(for: skill.id ?? 0)
                suggestion = coach.suggestNextSession(for: skill, history: allSessions)
                isStreakAtRisk = coach.isStreakAtRisk(history: allSessions)
                practiceTip = coach.getPracticeTip(for: skill)
            } else {
                // No skills yet — use generic tip
                practiceTip = "Add your first skill to get personalized AI coaching recommendations."
            }

            isLoading = false
        }
    }
}
