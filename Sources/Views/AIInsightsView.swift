import SwiftUI

struct AIInsightsView: View {
    let skills: [Skill]
    @State private var insights: [String] = []
    @State private var isLoading: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundColor(GraftColors.accent)
                Text("AI Insights")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)
                Spacer()
            }

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(GraftColors.accent)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if insights.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 24))
                        .foregroundColor(GraftColors.textSecondary.opacity(0.5))

                    Text("Log more sessions to unlock AI-powered insights about your practice patterns.")
                        .font(.system(size: 13))
                        .foregroundColor(GraftColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(insights, id: \.self) { insight in
                        InsightRow(text: insight)
                    }
                }
            }
        }
        .onAppear {
            loadInsights()
        }
    }

    private func loadInsights() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            insights = DatabaseService.shared.getAIPatternInsights()
            isLoading = false
        }
    }
}

// MARK: - Insight Row

struct InsightRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconFor(text))
                .font(.system(size: 14))
                .foregroundColor(GraftColors.accent)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(GraftColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(12)
        .background(GraftColors.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func iconFor(_ text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("morning") || lower.contains("afternoon") || lower.contains("evening") || lower.contains("midday") || lower.contains("night") {
            return "clock.fill"
        } else if lower.contains("timer") || lower.contains("longer") {
            return "timer"
        } else if lower.contains("weekday") || lower.contains("weekend") {
            return "calendar"
        } else if lower.contains("streak") || lower.contains("days") {
            return "flame.fill"
        } else if lower.contains("momentum") || lower.contains("longer") || lower.contains("shorter") {
            return "chart.line.uptrend.xyaxis"
        } else if lower.contains("best") {
            return "star.fill"
        }
        return "lightbulb.fill"
    }
}

// MARK: - AI Suggestion Card

struct AISuggestionCard: View {
    let skills: [Skill]

    @State private var suggestion: String = ""
    @State private var isLoading: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(GraftColors.accent)
                Text("Suggested Next Session")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)
                Spacer()
            }

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(GraftColors.accent)
                    Spacer()
                }
            } else {
                HStack(spacing: 12) {
                    if let skill = suggestedSkill {
                        Text(skill.emoji)
                            .font(.system(size: 20))
                            .frame(width: 32, height: 32)
                            .background(GraftColors.accent.opacity(0.2))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(skill.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(GraftColors.textPrimary)
                            Text(suggestion)
                                .font(.system(size: 12))
                                .foregroundColor(GraftColors.textSecondary)
                        }
                    }

                    Spacer()
                }
            }
        }
        .onAppear {
            generateSuggestion()
        }
    }

    private var suggestedSkill: Skill? {
        guard !skills.isEmpty else { return nil }
        return skills.first
    }

    private func generateSuggestion() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let suggestions = generateSuggestions()
            suggestion = suggestions.randomElement() ?? "Time to practice!"
            isLoading = false
        }
    }

    private func generateSuggestions() -> [String] {
        let allSuggestions = [
            "Try a 25-minute focused session using the timer",
            "Practice something you haven't worked on in a while",
            "Start with a warm-up, then go deeper",
            "Set a specific goal for this session",
            "Mix up your routine — try a different approach",
            "Focus on the challenging part first",
            "End with something you enjoy",
            "Review your notes from last session"
        ]
        return allSuggestions
    }
}
