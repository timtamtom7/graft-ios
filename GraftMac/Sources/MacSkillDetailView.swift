import SwiftUI
import Charts

struct MacSkillDetailView: View {
    let skill: Skill
    let onLogSession: () -> Void
    let onViewMonth: () -> Void

    @State private var sessions: [Session] = []
    @State private var monthHours: Double = 0
    @State private var practiceDays: Int = 0
    @State private var weeklyData: [WeeklyBarData] = []
    @State private var showLogSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerCard
                if let _ = sessions.first(where: { $0.isFlowState }) {
                    flowStateBadge
                }
                statsRow
                weekChartCard
                recentSessionsCard
            }
            .padding(24)
        }
        .background(GraftColors.background)
        .onAppear { loadData() }
        .sheet(isPresented: $showLogSheet) {
            MacLogSessionSheet(skillId: skill.id ?? 0) {
                loadData()
            }
        }
    }

    // MARK: - Flow State Badge

    private var flowStateBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("Flow State Achieved")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text("You hit deep focus — >45 min, no interruptions, followed routine.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color(hex: "7C3AED"), Color(hex: "4F46E5")],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: 20) {
            Text(skill.emoji)
                .font(.system(size: 72))

            VStack(alignment: .leading, spacing: 6) {
                Text(skill.name)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(GraftColors.textPrimary)
                Text("Skill Practice Tracker")
                    .font(.subheadline)
                    .foregroundColor(GraftColors.textSecondary)
            }

            Spacer()

            Button {
                showLogSheet = true
            } label: {
                Label("Log Session", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(GraftColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Log Session")
            .accessibilityHint("Opens a sheet to log a new practice session")
        }
        .padding(24)
        .background(GraftColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 16) {
            MacStatCard(
                value: String(format: "%.1f", monthHours),
                unit: "hrs",
                label: "This Month",
                icon: "clock.fill",
                color: GraftColors.accent
            )
            MacStatCard(
                value: "\(practiceDays)",
                unit: "days",
                label: "Practice Days",
                icon: "calendar",
                color: GraftColors.success
            )
            MacStatCard(
                value: "\(sessions.count)",
                unit: "sessions",
                label: "Total Sessions",
                icon: "checkmark.circle.fill",
                color: GraftColors.amber
            )
            MacStatCard(
                value: "\(currentStreak)",
                unit: "days",
                label: "Current Streak",
                icon: "flame.fill",
                color: .orange
            )
        }
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        let sortedDates = sessions
            .map { calendar.startOfDay(for: $0.practicedAt) }
            .reduce(into: [Date]()) { if !$0.contains($1) { $0.append($1) } }
            .sorted(by: >)

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        for date in sortedDates {
            if calendar.isDate(date, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            }
        }
        return streak
    }

    // MARK: - Week Chart Card

    private var weekChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.headline)
                    .foregroundColor(GraftColors.textPrimary)
                Spacer()
                Button("View Month") {
                    onViewMonth()
                }
                .font(.caption)
                .foregroundColor(GraftColors.accent)
                .buttonStyle(.plain)
                .accessibilityLabel("View Month")
                .accessibilityHint("Shows detailed monthly statistics")
            }

            if weeklyData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.largeTitle)
                        .foregroundColor(GraftColors.textSecondary)
                    Text("No practice data yet")
                        .font(.subheadline)
                        .foregroundColor(GraftColors.textSecondary)
                }
                .frame(height: 160)
                .frame(maxWidth: .infinity)
            } else {
                Chart(weeklyData) { item in
                    BarMark(
                        x: .value("Day", item.label),
                        y: .value("Hours", item.hours)
                    )
                    .foregroundStyle(GraftColors.accent.gradient)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(GraftColors.surfaceRaised)
                        AxisValueLabel {
                            if let hrs = value.as(Double.self) {
                                Text("\(Int(hrs))h")
                                    .font(.caption2)
                                    .foregroundColor(GraftColors.textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.caption2)
                                    .foregroundColor(GraftColors.textSecondary)
                            }
                        }
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(20)
        .background(GraftColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recent Sessions Card

    private var recentSessionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
                .foregroundColor(GraftColors.textPrimary)

            if sessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.largeTitle)
                        .foregroundColor(GraftColors.textSecondary)
                    Text("No sessions logged yet")
                        .font(.subheadline)
                        .foregroundColor(GraftColors.textSecondary)
                    Button("Log Your First Session") {
                        showLogSheet = true
                    }
                    .font(.caption)
                    .foregroundColor(GraftColors.accent)
                    .buttonStyle(.plain)
                    .accessibilityLabel("Log Your First Session")
                    .accessibilityHint("Opens a sheet to log your first practice session")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 0) {
                    ForEach(sessions.prefix(8)) { session in
                        MacSessionRow(session: session)
                        if session.id != sessions.prefix(8).last?.id {
                            Divider()
                                .background(GraftColors.surfaceRaised)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(GraftColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Data Loading

    private func loadData() {
        guard let skillId = skill.id else { return }
        let allSessions = DatabaseService.shared.getAllSessions(for: skillId)
        sessions = allSessions.sorted { $0.practicedAt > $1.practicedAt }

        // Monthly hours
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let monthSessions = allSessions.filter { $0.practicedAt >= monthStart }
        let totalMinutes = monthSessions.reduce(0) { $0 + $1.durationMinutes }
        monthHours = Double(totalMinutes) / 60.0
        practiceDays = Set(monthSessions.map { calendar.component(.day, from: $0.practicedAt) }).count

        // Weekly data
        weeklyData = buildWeeklyData(sessions: allSessions)

        if allSessions.isEmpty {
            weeklyData = [
                WeeklyBarData(label: "Mon", hours: 0.5),
                WeeklyBarData(label: "Tue", hours: 1.0),
                WeeklyBarData(label: "Wed", hours: 0),
                WeeklyBarData(label: "Thu", hours: 0.75),
                WeeklyBarData(label: "Fri", hours: 1.5),
                WeeklyBarData(label: "Sat", hours: 0.75),
                WeeklyBarData(label: "Sun", hours: 0),
            ]
        }
    }

    private func buildWeeklyData(sessions: [Session]) -> [WeeklyBarData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        return (0..<7).reversed().map { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return WeeklyBarData(label: "-", hours: 0)
            }
            let dayOfWeek = calendar.component(.weekday, from: date) - 1
            let label = dayLabels[dayOfWeek]

            let dayStart = calendar.startOfDay(for: date)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                return WeeklyBarData(label: label, hours: 0)
            }

            let dayMinutes = sessions
                .filter { $0.practicedAt >= dayStart && $0.practicedAt < dayEnd }
                .reduce(0) { $0 + $1.durationMinutes }

            return WeeklyBarData(label: label, hours: Double(dayMinutes) / 60.0)
        }
    }
}

// MARK: - Supporting Types

struct WeeklyBarData: Identifiable {
    let id = UUID()
    let label: String
    let hours: Double
}

struct MacSessionRow: View {
    let session: Session

    var body: some View {
        HStack(spacing: 16) {
            // Date
            Text(formattedDate)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(GraftColors.textSecondary)
                .frame(width: 130, alignment: .leading)

            // Duration
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(session.formattedDuration)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
            }
            .foregroundColor(GraftColors.accent)

            Spacer()

            // Feel rating
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { n in
                    Circle()
                        .fill(n <= session.feelRating ? GraftColors.accent : GraftColors.surfaceRaised)
                        .frame(width: 6, height: 6)
                }
            }

            // Notes
            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(GraftColors.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: 200, alignment: .trailing)
            }
        }
        .padding(.vertical, 10)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: session.practicedAt)
    }
}

// MARK: - Stat Card

struct MacStatCard: View {
    let value: String
    let unit: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .foregroundColor(GraftColors.textSecondary)
            }
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(GraftColors.textPrimary)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(GraftColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(GraftColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
