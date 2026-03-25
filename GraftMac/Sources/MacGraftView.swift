import SwiftUI

struct MacGraftView: View {
    @State private var skills: [Skill] = []
    @State private var selectedSkill: Skill?
    @State private var showLogSession = false
    @State private var showSettings = false
    @State private var showAnalytics = false

    var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            detailView
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            loadSkills()
        }
    }

    private var sidebarView: some View {
        List(selection: $selectedSkill) {
            Section("Skills") {
                ForEach(skills) { skill in
                    NavigationLink(value: skill) {
                        HStack {
                            Text(skill.emoji)
                                .font(.title2)
                            Text(skill.name)
                                .font(.body)
                        }
                    }
                }
            }

            Section {
                Button {
                    showAnalytics = true
                } label: {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 220)
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
    }

    @ViewBuilder
    private var detailView: some View {
        if let skill = selectedSkill {
            SkillDetailMacView(skill: skill, onLogSession: { showLogSession = true })
        } else {
            ContentUnavailableView(
                "Select a Skill",
                systemImage: "book.fill",
                description: Text("Choose a skill from the sidebar to start practicing.")
            )
        }
    }

    private func loadSkills() {
        // Load skills from database
        // For now, use sample data
        skills = [
            Skill(id: 1, name: "Piano", emoji: "🎹", isActive: true),
            Skill(id: 2, name: "Guitar", emoji: "🎸", isActive: true),
            Skill(id: 3, name: "Coding", emoji: "💻", isActive: true),
        ]
    }
}

struct SkillDetailMacView: View {
    let skill: Skill
    let onLogSession: () -> Void
    @State private var recentSessions: [Session] = []
    @State private var weeklyTotalMinutes = 0
    @State private var streakDays = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack(spacing: 16) {
                    Text(skill.emoji)
                        .font(.system(size: 64))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(skill.name)
                            .font(.largeTitle.bold())
                        Text("Practice tracking")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        onLogSession()
                    } label: {
                        Label("Log Session", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "8B5CF6"))
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Stats
                HStack(spacing: 16) {
                    MacStatCard(value: "\(weeklyTotalMinutes)", label: "This Week (min)", icon: "clock.fill", color: .purple)
                    MacStatCard(value: "\(streakDays)", label: "Day Streak", icon: "flame.fill", color: .orange)
                    MacStatCard(value: "\(recentSessions.count)", label: "Sessions", icon: "checkmark.circle.fill", color: .green)
                }

                // Recent sessions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Sessions")
                        .font(.headline)

                    if recentSessions.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "clock.badge.questionmark")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No sessions logged yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(recentSessions.prefix(5)) { session in
                            HStack {
                                Text(formattedDate(session.date))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 120, alignment: .leading)

                                Text("\(session.durationMinutes) min")
                                    .font(.subheadline.monospacedDigit())

                                Spacer()

                                if let notes = session.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer()
            }
            .padding(24)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MacStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title.bold().monospacedDigit())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
