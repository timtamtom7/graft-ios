import SwiftUI

struct MacChallengesView: View {
    @StateObject private var r12Service = GraftR12R20Service.shared
    @State private var showCreateChallenge = false
    @State private var selectedChallenge: SharedChallenge?

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider().background(GraftColors.surfaceRaised)
            challengeListView
        }
        .background(GraftColors.background)
        .task {
            loadMockChallenges()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            Text("🏆")
                .font(.title2)
            Text("Group Challenges")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(GraftColors.textPrimary)
            Spacer()
            Button {
                showCreateChallenge = true
            } label: {
                Label("Create", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(GraftColors.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(GraftColors.surface)
    }

    // MARK: - Challenge List

    private var challengeListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredChallenges) { challenge in
                    ChallengeCardView(challenge: challenge) {
                        selectedChallenge = challenge
                    }
                }

                if filteredChallenges.isEmpty {
                    emptyStateView
                }
            }
            .padding(16)
        }
    }

    private var filteredChallenges: [SharedChallenge] {
        r12Service.challenges.filter { $0.status == .active || $0.status == .upcoming }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "flag.2.crossed")
                .font(.system(size: 40))
                .foregroundColor(GraftColors.textSecondary.opacity(0.6))
            Text("No Active Challenges")
                .font(.headline)
                .foregroundColor(GraftColors.textPrimary)
            Text("Create a group challenge to start competing with others.")
                .font(.subheadline)
                .foregroundColor(GraftColors.textSecondary)
                .multilineTextAlignment(.center)
            Button("Create Challenge") {
                showCreateChallenge = true
            }
            .buttonStyle(.borderedProminent)
            .tint(GraftColors.accentMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Mock Data

    private func loadMockChallenges() {
        guard r12Service.challenges.isEmpty else { return }

        let mockChallenges = [
            SharedChallenge(
                id: UUID(),
                name: "30-Day Guitar Challenge",
                challengeType: .streak,
                description: "Practice guitar every day for 30 days",
                participantIDs: ["user1", "user2", "user3", "user4", "user5", "user6", "user7", "user8", "user9", "user10", "user11", "user12"],
                startDate: Date().addingTimeInterval(-86400 * 5),
                endDate: Date().addingTimeInterval(86400 * 25),
                goal: SharedChallenge.ChallengeGoal(targetValue: 30, unit: "days", isTeamGoal: false),
                status: .active,
                leaderboard: [
                    SharedChallenge.LeaderboardEntry(id: UUID(), userID: "user1", displayName: "GuitarMaster", currentValue: 25, rank: 1, trend: .same),
                    SharedChallenge.LeaderboardEntry(id: UUID(), userID: "user2", displayName: "ChordKing", currentValue: 23, rank: 2, trend: .up),
                    SharedChallenge.LeaderboardEntry(id: UUID(), userID: "user3", displayName: "MelodyPro", currentValue: 22, rank: 3, trend: .down),
                    SharedChallenge.LeaderboardEntry(id: UUID(), userID: "user4", displayName: "Strummer", currentValue: 20, rank: 4, trend: .same),
                    SharedChallenge.LeaderboardEntry(id: UUID(), userID: "user5", displayName: "FretNinja", currentValue: 18, rank: 5, trend: .up),
                ]
            ),
            SharedChallenge(
                id: UUID(),
                name: "Coding Sprint",
                challengeType: .custom,
                description: "Commit code every day for 2 weeks",
                participantIDs: ["userA", "userB", "userC"],
                startDate: Date().addingTimeInterval(-86400 * 3),
                endDate: Date().addingTimeInterval(86400 * 11),
                goal: SharedChallenge.ChallengeGoal(targetValue: 14, unit: "commits", isTeamGoal: false),
                status: .active,
                leaderboard: [
                    SharedChallenge.LeaderboardEntry(id: UUID(), userID: "userA", displayName: "CodeNinja", currentValue: 10, rank: 1, trend: .same),
                    SharedChallenge.LeaderboardEntry(id: UUID(), userID: "userB", displayName: "DevGuru", currentValue: 8, rank: 2, trend: .up),
                    SharedChallenge.LeaderboardEntry(id: UUID(), userID: "userC", displayName: "BugHunter", currentValue: 6, rank: 3, trend: .down),
                ]
            ),
            SharedChallenge(
                id: UUID(),
                name: "Piano Marathon",
                challengeType: .distance,
                description: "Log the most practice minutes this month",
                participantIDs: ["pianist1", "pianist2", "pianist3", "pianist4"],
                startDate: Date().addingTimeInterval(-86400 * 10),
                endDate: Date().addingTimeInterval(86400 * 20),
                goal: SharedChallenge.ChallengeGoal(targetValue: 3000, unit: "minutes", isTeamGoal: true),
                status: .active,
                leaderboard: [
                    SharedChallenge.LeaderboardEntry(id: UUID(), userID: "pianist1", displayName: "KeysMaster", currentValue: 1200, rank: 1, trend: .same),
                    SharedChallenge.LeaderboardEntry(id: UUID(), userID: "pianist2", displayName: "PianoPro", currentValue: 1050, rank: 2, trend: .up),
                    SharedChallenge.LeaderboardEntry(id: UUID(), userID: "pianist3", displayName: "IvoryKeys", currentValue: 980, rank: 3, trend: .down),
                    SharedChallenge.LeaderboardEntry(id: UUID(), userID: "pianist4", displayName: "Benchwarmer", currentValue: 720, rank: 4, trend: .same),
                ]
            )
        ]

        for challenge in mockChallenges {
            r12Service.challenges.append(challenge)
        }
    }
}

// MARK: - Challenge Card

struct ChallengeCardView: View {
    let challenge: SharedChallenge
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.name)
                        .font(.headline)
                        .foregroundColor(GraftColors.textPrimary)

                    Text("\(challenge.participantIDs.count) participants")
                        .font(.caption)
                        .foregroundColor(GraftColors.textSecondary)
                }

                Spacer()

                StatusBadge(status: challenge.status)
            }
            .padding(16)

            Divider().background(GraftColors.surfaceRaised)

            // Leaderboard preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Leaderboard")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(GraftColors.textSecondary)
                    .textCase(.uppercase)

                ForEach(Array(challenge.leaderboard.prefix(3).enumerated()), id: \.element.id) { index, entry in
                    LeaderboardRowView(entry: entry, isTopThree: index < 3)
                }

                if challenge.leaderboard.count > 3 {
                    Text("+\(challenge.leaderboard.count - 3) more")
                        .font(.caption)
                        .foregroundColor(GraftColors.textSecondary.opacity(0.7))
                        .padding(.leading, 4)
                }
            }
            .padding(16)

            Divider().background(GraftColors.surfaceRaised)

            // Actions
            HStack {
                Button("View Details") {
                    onTap()
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.medium))
                .foregroundColor(GraftColors.accent)

                Spacer()

                Button("Join Challenge") {
                    // Join action
                }
                .buttonStyle(.borderedProminent)
                .tint(GraftColors.accentMuted)
                .controlSize(.small)
            }
            .padding(16)
        }
        .background(GraftColors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(GraftColors.surfaceRaised, lineWidth: 1)
        )
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRowView: View {
    let entry: SharedChallenge.LeaderboardEntry
    let isTopThree: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Rank
            Text("#\(entry.rank)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(rankColor)
                .frame(width: 28, alignment: .leading)

            // Name
            Text(entry.displayName)
                .font(.subheadline)
                .foregroundColor(GraftColors.textPrimary)
                .lineLimit(1)

            Spacer()

            // Value
            Text("\(Int(entry.currentValue)) \(entry.goal.unit)")
                .font(.caption)
                .foregroundColor(GraftColors.textSecondary)

            // Trend
            Image(systemName: trendIcon)
                .font(.caption2)
                .foregroundColor(trendColor)
        }
        .padding(.vertical, 4)
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return GraftColors.gold
        case 2: return GraftColors.silver
        case 3: return GraftColors.bronze
        default: return GraftColors.textSecondary
        }
    }

    private var trendIcon: String {
        switch entry.trend {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .same: return "minus"
        }
    }

    private var trendColor: Color {
        switch entry.trend {
        case .up: return GraftColors.upTrend
        case .down: return GraftColors.downTrend
        case .same: return GraftColors.textSecondary
        }
    }
}

extension SharedChallenge.LeaderboardEntry {
    var goal: SharedChallenge.ChallengeGoal { SharedChallenge.ChallengeGoal() }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: SharedChallenge.Status

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2.weight(.semibold))
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .cornerRadius(6)
    }

    private var textColor: Color {
        switch status {
        case .active: return GraftColors.success
        case .upcoming: return GraftColors.accent
        case .completed: return GraftColors.textSecondary
        case .cancelled: return GraftColors.downTrend
        }
    }

    private var backgroundColor: Color {
        textColor.opacity(0.15)
    }
}


