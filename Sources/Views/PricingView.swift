import SwiftUI

enum SubscriptionTier: String, CaseIterable {
    case free = "free"
    case track = "track"
    case master = "master"

    var name: String {
        switch self {
        case .free: return "Free"
        case .track: return "Track"
        case .master: return "Master"
        }
    }

    var price: String {
        switch self {
        case .free: return "Free"
        case .track: return "$2.99/mo"
        case .master: return "$5.99/mo"
        }
    }

    var monthlyPrice: Double {
        switch self {
        case .free: return 0
        case .track: return 2.99
        case .master: return 5.99
        }
    }

    var tagline: String {
        switch self {
        case .free: return "Start building"
        case .track: return "Go deeper"
        case .master: return "Full mastery"
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "1 skill at a time",
                "30-day history",
                "Basic monthly heatmap",
                "Log sessions manually"
            ]
        case .track:
            return [
                "Unlimited session logging",
                "1-year history",
                "Monthly heatmap",
                "Practice frequency insights"
            ]
        case .master:
            return [
                "Everything in Track",
                "Multiple skills simultaneously",
                "Detailed analytics",
                "Export your data",
                "Practice streaks"
            ]
        }
    }

    var isPopular: Bool {
        self == .track
    }
}

struct PricingView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTier: SubscriptionTier = .track
    @State private var showPurchaseConfirmation: Bool = false

    var onTierSelected: ((SubscriptionTier) -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        headerSection

                        tierCards

                        featureComparison

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Choose Your Path")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(GraftColors.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Put in the work.")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(GraftColors.textPrimary)

            Text("Every master was once a beginner. Choose how much structure you want on your journey.")
                .font(.system(size: 14))
                .foregroundColor(GraftColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.top, 8)
    }

    // MARK: - Tier Cards

    private var tierCards: some View {
        VStack(spacing: 12) {
            ForEach(SubscriptionTier.allCases, id: \.self) { tier in
                TierCard(
                    tier: tier,
                    isSelected: selectedTier == tier,
                    onSelect: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTier = tier
                        }
                    }
                )
            }
        }
    }

    // MARK: - Feature Comparison

    private var featureComparison: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("What's included")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)

                VStack(spacing: 12) {
                    featureRow(feature: "Skill slots", free: "1", track: "1", master: "Unlimited")
                    Divider().background(GraftColors.textSecondary.opacity(0.2))
                    featureRow(feature: "History", free: "30 days", track: "1 year", master: "Unlimited")
                    Divider().background(GraftColors.textSecondary.opacity(0.2))
                    featureRow(feature: "Heatmap", free: "Basic", track: "Monthly", master: "Monthly + weekly")
                    Divider().background(GraftColors.textSecondary.opacity(0.2))
                    featureRow(feature: "Data export", free: "—", track: "—", master: "✓")
                    Divider().background(GraftColors.textSecondary.opacity(0.2))
                    featureRow(feature: "Practice streaks", free: "—", track: "—", master: "✓")
                }
            }
            .padding(20)
        }
    }

    private func featureRow(feature: String, free: String, track: String, master: String) -> some View {
        HStack {
            Text(feature)
                .font(.system(size: 13))
                .foregroundColor(GraftColors.textSecondary)
                .frame(width: 100, alignment: .leading)

            Spacer()

            Text(free)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(tierValueColor(free))
                .frame(width: 60)

            Text(track)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(tierValueColor(track))
                .frame(width: 60)

            Text(master)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(tierValueColor(master))
                .frame(width: 60)
        }
    }

    private func tierValueColor(_ value: String) -> Color {
        if value == "✓" {
            return GraftColors.success
        } else if value == "—" {
            return GraftColors.textSecondary.opacity(0.4)
        } else if value == "Unlimited" {
            return GraftColors.accent
        }
        return GraftColors.textPrimary
    }
}

// MARK: - Tier Card

struct TierCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Popular badge for Track
                if tier.isPopular {
                    HStack {
                        Text("Most popular")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(0.5)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [GraftColors.accent, GraftColors.accentMuted],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tier.name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(GraftColors.textPrimary)

                            Text(tier.tagline)
                                .font(.system(size: 12))
                                .foregroundColor(GraftColors.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(tier.price)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(tier == .free ? GraftColors.textSecondary : GraftColors.accent)
                        }
                    }

                    // Feature bullets
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(tier.features, id: \.self) { feature in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(GraftColors.accent)
                                    .frame(width: 12)

                                Text(feature)
                                    .font(.system(size: 13))
                                    .foregroundColor(GraftColors.textSecondary)
                            }
                        }
                    }

                    // Select button
                    HStack {
                        Spacer()
                        Text(isSelected ? "Selected" : "Choose")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isSelected ? GraftColors.accent : GraftColors.textSecondary)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .background(isSelected ? GraftColors.accent.opacity(0.15) : GraftColors.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(16)
            }
            .background(GraftColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? GraftColors.accent : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
