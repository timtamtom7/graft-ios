import SwiftUI

struct MacSharedStreaksView: View {
    @StateObject private var accountabilityService = AccountabilityService.shared

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider().background(GraftColors.surfaceRaised)

            if accountabilityService.partners.isEmpty {
                emptyStateView
            } else {
                partnerStreaksList
            }
        }
        .background(GraftColors.background)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            Text("🤝")
                .font(.title2)
            Text("Practice Streaks")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(GraftColors.textPrimary)
            Spacer()

            Button {
                // Invite partner action
            } label: {
                Label("Invite Partner", systemImage: "person.badge.plus")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(GraftColors.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(GraftColors.surface)
    }

    // MARK: - Partner List

    private var partnerStreaksList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(accountabilityService.partners) { partner in
                    PartnerStreakCard(
                        partner: partner,
                        onSendEncouragement: { emoji in
                            accountabilityService.sendEncouragement(to: partner.id, emoji: emoji)
                        }
                    )
                }
            }
            .padding(16)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundColor(GraftColors.textSecondary.opacity(0.6))
            Text("No Accountability Partners")
                .font(.headline)
                .foregroundColor(GraftColors.textPrimary)
            Text("Invite a practice partner to share your progress and keep each other accountable.")
                .font(.subheadline)
                .foregroundColor(GraftColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            HStack(spacing: 12) {
                Button("Invite Partner") {
                    // Show invite sheet
                }
                .buttonStyle(.borderedProminent)
                .tint(GraftColors.accentMuted)

                Button("Accept Invite") {
                    // Show accept sheet
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Partner Streak Card

struct PartnerStreakCard: View {
    let partner: AccountabilityPartner
    let onSendEncouragement: (String) -> Void

    @State private var showEncouragementPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Partner info header
            HStack(alignment: .center, spacing: 14) {
                // Avatar
                Circle()
                    .fill(avatarColor)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(partner.name.prefix(1).uppercased())
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(GraftColors.textOnAccent)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(partner.name)
                        .font(.headline)
                        .foregroundColor(GraftColors.textPrimary)

                    HStack(spacing: 6) {
                        Text(partner.skill)
                            .font(.caption)
                            .foregroundColor(GraftColors.textSecondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(GraftColors.textSecondary.opacity(0.5))
                    }
                }

                Spacer()

                // Streak badge
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(partner.streak > 0 ? .orange : GraftColors.textSecondary)
                        Text("\(partner.streak)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(partner.streak > 0 ? GraftColors.textPrimary : GraftColors.textSecondary)
                    }
                    Text("day streak")
                        .font(.caption2)
                        .foregroundColor(GraftColors.textSecondary)
                }
            }
            .padding(16)

            Divider().background(GraftColors.surfaceRaised)

            // Last check-in
            if let lastCheckIn = partner.lastCheckIn {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(GraftColors.success)
                        .font(.caption)
                    Text("Last check-in: \(lastCheckIn, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(GraftColors.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(GraftColors.amber)
                        .font(.caption)
                    Text("No check-in recorded yet")
                        .font(.caption)
                        .foregroundColor(GraftColors.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            Divider().background(GraftColors.surfaceRaised)

            // Encouragement
            HStack(spacing: 8) {
                Text("Send encouragement:")
                    .font(.caption)
                    .foregroundColor(GraftColors.textSecondary)

                ForEach(encouragementEmojis, id: \.self) { emoji in
                    Button {
                        onSendEncouragement(emoji)
                    } label: {
                        Text(emoji)
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(GraftColors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(GraftColors.surfaceRaised, lineWidth: 1)
        )
    }

    private var encouragementEmojis: [String] {
        ["🔥", "💪", "🎉", "👏", "⭐"]
    }

    private var avatarColor: Color {
        switch partner.skill.lowercased() {
        case "guitar": return GraftColors.avatarGuitar
        case "piano": return GraftColors.avatarPiano
        case "coding": return GraftColors.avatarCoding
        case "drums": return GraftColors.avatarDrums
        case "vocals": return GraftColors.avatarVocals
        default: return GraftColors.accentMuted
        }
    }
}
