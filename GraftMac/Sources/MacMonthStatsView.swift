import SwiftUI

struct MacMonthStatsView: View {
    let skill: Skill

    @Environment(\.dismiss) private var dismiss
    @State private var currentMonth: Date = Date()
    @State private var sessionsByDay: [Int: [Session]] = [:]
    @State private var totalHours: Double = 0
    @State private var totalSessions: Int = 0
    @State private var consistencyScore: Int = 0

    private let calendar = Calendar.current
    private let cellSize: CGFloat = 36

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Monthly Stats")
                    .font(.headline)
                    .foregroundColor(GraftColors.textPrimary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(GraftColors.textSecondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
                .accessibilityHint("Closes the monthly statistics view")
            }
            .padding(20)
            .background(GraftColors.surface)

            Divider().background(GraftColors.surfaceRaised)

            ScrollView {
                VStack(spacing: 24) {
                    monthHeader
                    weekdayLabels
                    calendarGrid
                    summaryCards
                }
                .padding(24)
            }

            Spacer()
        }
        .frame(width: 480, height: 580)
        .background(GraftColors.background)
        .onAppear { loadSessions() }
        .onChange(of: currentMonth) { _, _ in loadSessions() }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(GraftColors.accent)
                    .frame(width: 32, height: 32)
                    .background(GraftColors.surfaceRaised)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous Month")
            .accessibilityHint("Navigate to the previous month")

            Spacer()

            Text(monthYearString)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(GraftColors.textPrimary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isCurrentMonth ? GraftColors.textSecondary : GraftColors.accent)
                    .frame(width: 32, height: 32)
                    .background(GraftColors.surfaceRaised)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isCurrentMonth)
            .accessibilityLabel("Next Month")
            .accessibilityHint("Navigate to the next month")
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Weekday Labels

    private var weekdayLabels: some View {
        HStack(spacing: 4) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
                    .frame(width: cellSize, height: 20)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysInMonth
        let offset = firstWeekdayOffset

        return VStack(spacing: 4) {
            ForEach(0..<6, id: \.self) { week in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { weekday in
                        let index = week * 7 + weekday
                        let dayNumber = index - offset + 1

                        if dayNumber > 0 && dayNumber <= days {
                            let hasSessions = (sessionsByDay[dayNumber]?.count ?? 0) > 0
                            let sessionCount = sessionsByDay[dayNumber]?.count ?? 0

                            VStack(spacing: 3) {
                                Text("\(dayNumber)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(GraftColors.textPrimary)

                                if hasSessions {
                                    HStack(spacing: 2) {
                                        ForEach(0..<min(sessionCount, 3), id: \.self) { _ in
                                            Circle()
                                                .fill(GraftColors.accent)
                                                .frame(width: 4, height: 4)
                                        }
                                    }
                                } else {
                                    Spacer().frame(height: 4)
                                }
                            }
                            .frame(width: cellSize, height: cellSize)
                            .background(GraftColors.surfaceRaised)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30
    }

    private var firstWeekdayOffset: Int {
        var components = calendar.dateComponents([.year, .month], from: currentMonth)
        components.day = 1
        guard let firstDay = calendar.date(from: components) else { return 0 }
        return calendar.component(.weekday, from: firstDay) - 1
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 16) {
            summaryItem(
                icon: "clock.fill",
                value: String(format: "%.1f", totalHours),
                unit: "hrs",
                label: "Total Practice",
                color: GraftColors.accent
            )
            summaryItem(
                icon: "checkmark.circle.fill",
                value: "\(totalSessions)",
                unit: "sessions",
                label: "Sessions",
                color: GraftColors.success
            )
            summaryItem(
                icon: "chart.line.uptrend.xyaxis",
                value: "\(consistencyScore)",
                unit: "%",
                label: "Consistency",
                color: GraftColors.amber
            )
        }
    }

    private func summaryItem(icon: String, value: String, unit: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .foregroundColor(GraftColors.textSecondary)
            }
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(GraftColors.textPrimary)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(GraftColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(GraftColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Data Loading

    private func loadSessions() {
        guard let skillId = skill.id else { return }
        let allSessions = DatabaseService.shared.getAllSessions(for: skillId)

        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!

        let monthSessions = allSessions.filter { $0.practicedAt >= monthStart && $0.practicedAt < monthEnd }

        var byDay: [Int: [Session]] = [:]
        for session in monthSessions {
            let day = calendar.component(.day, from: session.practicedAt)
            byDay[day, default: []].append(session)
        }

        sessionsByDay = byDay
        totalSessions = monthSessions.count
        totalHours = Double(monthSessions.reduce(0) { $0 + $1.durationMinutes }) / 60.0

        let daysWithPractice = byDay.keys.count
        let daysInMonthCount = daysInMonth
        consistencyScore = daysInMonthCount > 0 ? Int((Double(daysWithPractice) / Double(daysInMonthCount)) * 100) : 0
    }
}
