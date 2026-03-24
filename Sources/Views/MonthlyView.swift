import SwiftUI

struct MonthlyView: View {
    let skill: Skill

    @Environment(\.dismiss) private var dismiss
    @State private var currentMonth: Date = Date()
    @State private var sessionsByDay: [Date: [Session]] = [:]
    @State private var selectedDaySessions: [Session] = []
    @State private var selectedDayDate: Date?
    @State private var showDayDetail: Bool = false

    private let calendar = Calendar.current
    private let cellSize: CGFloat = 40
    private let maxWeeklyMinutes: CGFloat = 300

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        monthHeader
                        weekdayLabels
                        heatmapGrid
                        monthSummary
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Monthly View")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(GraftColors.accent)
                }
            }
            .onAppear {
                loadSessions()
            }
            .onChange(of: currentMonth) { _, _ in
                loadSessions()
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(GraftColors.accent)
                    .frame(width: 36, height: 36)
                    .background(GraftColors.surface)
                    .clipShape(Circle())
            }

            Spacer()

            Text(monthYearString)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(GraftColors.textPrimary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(GraftColors.accent)
                    .frame(width: 36, height: 36)
                    .background(GraftColors.surface)
                    .clipShape(Circle())
            }
            .disabled(calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month))
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    // MARK: - Weekday Labels

    private var weekdayLabels: some View {
        HStack(spacing: 0) {
            ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
                    .frame(width: cellSize, height: 20)
            }
        }
    }

    // MARK: - Heatmap Grid

    private var heatmapGrid: some View {
        VStack(spacing: 6) {
            ForEach(weeksInMonth.indices, id: \.self) { weekIndex in
                HStack(spacing: 6) {
                    ForEach(weeksInMonth[weekIndex].indices, id: \.self) { dayIndex in
                        let date = weeksInMonth[weekIndex][dayIndex]
                        if let date = date {
                            let totalMinutes = sessionsForDay(date).reduce(0) { $0 + $1.durationMinutes }
                            let intensity = min(CGFloat(totalMinutes) / maxWeeklyMinutes, 1.0)
                            let isToday = calendar.isDateInToday(date)
                            let isSelected = selectedDayDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false

                            dayCell(date: date, intensity: intensity, isToday: isToday, isSelected: isSelected)
                        } else {
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showDayDetail) {
            if let date = selectedDayDate {
                DayDetailSheet(date: date, sessions: selectedDaySessions) {
                    loadSessions()
                }
            }
        }
    }

    private func dayCell(date: Date, intensity: Double, isToday: Bool, isSelected: Bool) -> some View {
        Button {
            selectedDayDate = date
            selectedDaySessions = sessionsForDay(date)
            showDayDetail = true
        } label: {
            ZStack {
                Circle()
                    .fill(intensity > 0
                          ? GraftColors.accent.opacity(0.2 + intensity * 0.8)
                          : GraftColors.surface)
                    .frame(width: cellSize, height: cellSize)

                if intensity > 0 {
                    Circle()
                        .fill(GraftColors.accent.opacity(intensity))
                        .frame(width: cellSize * 0.5, height: cellSize * 0.5)
                }

                if isToday {
                    Circle()
                        .strokeBorder(GraftColors.accent, lineWidth: 1.5)
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
    }

    // MARK: - Month Summary

    private var monthSummary: some View {
        LiquidGlassCard {
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(formattedMonthlyTime)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(GraftColors.textPrimary)
                    Text("Total time")
                        .font(.system(size: 11))
                        .foregroundColor(GraftColors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(practiceDaysCount)")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(GraftColors.accent)
                    Text("Practice days")
                        .font(.system(size: 11))
                        .foregroundColor(GraftColors.textSecondary)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Helpers

    private var weeksInMonth: [[Date?]] {
        var weeks: [[Date?]] = []
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return weeks
        }

        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let mondayOffset = (firstWeekday + 5) % 7

        var currentWeek: [Date?] = Array(repeating: nil, count: mondayOffset)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                currentWeek.append(date)
                if currentWeek.count == 7 {
                    weeks.append(currentWeek)
                    currentWeek = []
                }
            }
        }

        if !currentWeek.isEmpty {
            while currentWeek.count < 7 {
                currentWeek.append(nil)
            }
            weeks.append(currentWeek)
        }

        return weeks
    }

    private func sessionsForDay(_ date: Date) -> [Session] {
        guard let skillId = skill.id else { return [] }
        return sessionsByDay[calendar.startOfDay(for: date)] ?? []
    }

    private func loadSessions() {
        guard let skillId = skill.id else { return }
        let sessions = DatabaseService.shared.getSessions(for: skillId, in: currentMonth)

        var byDay: [Date: [Session]] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.practicedAt)
            byDay[day, default: []].append(session)
        }
        sessionsByDay = byDay
    }

    private var formattedMonthlyTime: String {
        guard let skillId = skill.id else { return "0m" }
        let total = DatabaseService.shared.getMonthlyTotalMinutes(for: skillId, month: currentMonth)
        let hours = total / 60
        let minutes = total % 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    private var practiceDaysCount: Int {
        guard let skillId = skill.id else { return 0 }
        return DatabaseService.shared.getPracticeDaysCount(for: skillId, month: currentMonth)
    }
}

// MARK: - Day Detail Sheet

struct DayDetailSheet: View {
    let date: Date
    let sessions: [Session]
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                VStack(spacing: 20) {
                    if sessions.isEmpty {
                        Spacer()
                        Text("No sessions on this day")
                            .font(.system(size: 15))
                            .foregroundColor(GraftColors.textSecondary)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(sessions) { session in
                                    sessionCard(session)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .navigationTitle(dayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(GraftColors.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var dayTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    private func sessionCard(_ session: Session) -> some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(session.formattedDuration)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(GraftColors.textPrimary)

                    Spacer()

                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { rating in
                            Circle()
                                .fill(rating <= session.feelRating ? GraftColors.accent : GraftColors.surfaceRaised)
                                .frame(width: 8, height: 8)
                        }
                    }
                }

                if let notes = session.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 13))
                        .foregroundColor(GraftColors.textSecondary)
                        .lineLimit(3)
                }

                Text(timeString(for: session.practicedAt))
                    .font(.system(size: 11))
                    .foregroundColor(GraftColors.textSecondary.opacity(0.7))
            }
            .padding(16)
        }
    }

    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
