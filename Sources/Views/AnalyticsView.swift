import SwiftUI

struct AnalyticsView: View {
    let skills: [Skill]

    @Environment(\.dismiss) private var dismiss
    @State private var personalRecords: PersonalRecord = .empty
    @State private var trendData: [(weekStart: Date, totalMinutes: Int)] = []
    @State private var weeklyGoal: UserGoal?
    @State private var monthlyGoal: UserGoal?
    @State private var showGoalSheet: Bool = false
    @State private var selectedGoalType: UserGoal.GoalType = .weekly

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        personalRecordsSection
                        trendLineSection
                        goalProgressSection
                        if skills.count > 1 {
                            skillComparisonSection
                        }
                        aiInsightsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Analytics")
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
            .sheet(isPresented: $showGoalSheet) {
                GoalSettingSheet(
                    goalType: selectedGoalType,
                    existingGoal: selectedGoalType == .weekly ? weeklyGoal : monthlyGoal
                ) { goal in
                    if selectedGoalType == .weekly {
                        weeklyGoal = goal
                    } else {
                        monthlyGoal = goal
                    }
                    loadData()
                }
            }
            .onAppear {
                loadData()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Personal Records

    private var personalRecordsSection: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Personal Records")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)

                HStack(spacing: 16) {
                    recordItem(
                        icon: "timer",
                        value: formattedLongestSession,
                        label: "Longest session"
                    )
                    recordItem(
                        icon: "star.fill",
                        value: personalRecords.bestFeelRating > 0 ? "\(personalRecords.bestFeelRating)⭐" : "—",
                        label: "Best feel"
                    )
                    recordItem(
                        icon: "chart.bar.fill",
                        value: formattedBestWeek,
                        label: "Best week"
                    )
                }
            }
            .padding(20)
        }
    }

    private func recordItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(GraftColors.accent)

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(GraftColors.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(GraftColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Trend Line

    private var trendLineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Practice Trend")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(GraftColors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)

            LiquidGlassCard {
                VStack(spacing: 12) {
                    TrendLineChart(data: trendData)
                        .frame(height: 140)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)

                    HStack {
                        Text(trendInsight)
                            .font(.system(size: 12))
                            .foregroundColor(GraftColors.textSecondary)
                            .italic()
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private var trendInsight: String {
        guard trendData.count >= 2 else { return "Keep practicing to see your trend." }
        let recent = trendData.suffix(4).reduce(0) { $0 + $1.totalMinutes }
        let previous = trendData.dropLast(4).suffix(4).reduce(0) { $0 + $1.totalMinutes }

        if recent > previous && previous > 0 {
            return "Trending up ↑"
        } else if recent < previous && recent > 0 {
            return "Trending down ↓"
        }
        return "Staying consistent"
    }

    // MARK: - Goal Progress

    private var goalProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Goals")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)
                Spacer()
                Button {
                    selectedGoalType = .weekly
                    showGoalSheet = true
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14))
                        .foregroundColor(GraftColors.accent)
                }
            }

            VStack(spacing: 10) {
                if let weekly = weeklyGoal {
                    goalCard(goal: weekly, type: .weekly)
                } else {
                    goalPlaceholder(type: .weekly)
                }

                if let monthly = monthlyGoal {
                    goalCard(goal: monthly, type: .monthly)
                } else {
                    goalPlaceholder(type: .monthly)
                }
            }
        }
    }

    private func goalCard(goal: UserGoal, type: UserGoal.GoalType) -> some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(type.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(GraftColors.textPrimary)
                    Spacer()
                    Text("\(goal.currentMinutes / 60)h \(goal.currentMinutes % 60)m / \(goal.targetMinutes / 60)h")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(GraftColors.textSecondary)
                }

                ProgressBarGraphic(progress: goal.progress, height: 8)

                Text("\(Int(goal.progress * 100))% complete")
                    .font(.system(size: 11))
                    .foregroundColor(goal.progress >= 1.0 ? GraftColors.success : GraftColors.textSecondary)
            }
            .padding(16)
        }
    }

    private func goalPlaceholder(type: UserGoal.GoalType) -> some View {
        Button {
            selectedGoalType = type
            showGoalSheet = true
        } label: {
            HStack {
                Text("Set \(type.displayName.lowercased()) goal")
                    .font(.system(size: 13))
                    .foregroundColor(GraftColors.textSecondary)
                Spacer()
                Image(systemName: "plus")
                    .foregroundColor(GraftColors.accent)
            }
            .padding(16)
            .background(GraftColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Skill Comparison

    private var skillComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skill Comparison")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(GraftColors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)

            LiquidGlassCard {
                SkillComparisonChart(skills: DatabaseService.shared.getSkillComparisonData())
                    .frame(maxWidth: .infinity)
                    .padding(16)
            }
        }
    }

    // MARK: - Helpers

    private var formattedLongestSession: String {
        let minutes = personalRecords.longestSessionMinutes
        if minutes == 0 { return "—" }
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(mins)m"
    }

    private var formattedBestWeek: String {
        let minutes = personalRecords.mostConsistentWeekMinutes
        if minutes == 0 { return "—" }
        let hours = minutes / 60
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(minutes)m"
    }

    private func loadData() {
        personalRecords = DatabaseService.shared.getPersonalRecords()
        trendData = DatabaseService.shared.getTrendData()
        weeklyGoal = DatabaseService.shared.getActiveGoal(for: .weekly)
        monthlyGoal = DatabaseService.shared.getActiveGoal(for: .monthly)
    }

    // MARK: - AI Insights Section

    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LiquidGlassCard {
                VStack(spacing: 16) {
                    AIInsightsView(skills: skills)
                    Divider().background(GraftColors.textSecondary.opacity(0.2))
                    AISuggestionCard(skills: skills)
                }
                .padding(16)
            }
        }
    }
}

// MARK: - Trend Line Chart

struct TrendLineChart: View {
    let data: [(weekStart: Date, totalMinutes: Int)]

    private let chartHeight: CGFloat = 120

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = chartHeight
            let maxMinutes = max(data.map { $0.totalMinutes }.max() ?? 1, 1)

            ZStack {
                // Y-axis labels
                VStack {
                    Text("\(maxMinutes / 60)h")
                        .font(.system(size: 9))
                        .foregroundColor(GraftColors.textSecondary.opacity(0.6))
                    Spacer()
                    Text("0")
                        .font(.system(size: 9))
                        .foregroundColor(GraftColors.textSecondary.opacity(0.6))
                }
                .frame(width: 24)
                .frame(maxHeight: .infinity, alignment: .center)

                // Chart area
                HStack(alignment: .center, spacing: 4) {
                    ForEach(data.indices, id: \.self) { index in
                        let item = data[index]
                        let barHeight = max(CGFloat(item.totalMinutes) / CGFloat(maxMinutes) * height, 2)

                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [GraftColors.accent, GraftColors.accentMuted],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: max((width - 32) / CGFloat(max(data.count, 1)) - 4, 4), height: barHeight)

                            Text(weekLabel(for: item.weekStart))
                                .font(.system(size: 8))
                                .foregroundColor(GraftColors.textSecondary.opacity(0.6))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func weekLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - Skill Comparison Chart

struct SkillComparisonChart: View {
    let skills: [SkillComparisonData]

    var body: some View {
        VStack(spacing: 12) {
            if skills.isEmpty {
                Text("No data yet")
                    .font(.system(size: 13))
                    .foregroundColor(GraftColors.textSecondary)
            } else {
                let maxMinutes = max(skills.map { $0.totalMinutes }.max() ?? 1, 1)

                ForEach(skills) { skill in
                    HStack(spacing: 10) {
                        Text(skill.emoji)
                            .font(.system(size: 16))
                            .frame(width: 24)

                        Text(skill.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(GraftColors.textPrimary)
                            .frame(width: 70, alignment: .leading)

                        GeometryReader { geometry in
                            let barWidth = CGFloat(skill.totalMinutes) / CGFloat(maxMinutes) * geometry.size.width

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [GraftColors.accent, GraftColors.accentMuted],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(barWidth, 4), height: 16)
                        }
                        .frame(height: 16)

                        Text(skill.formattedTime)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(GraftColors.textSecondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
    }
}

// MARK: - Goal Setting Sheet

struct GoalSettingSheet: View {
    let goalType: UserGoal.GoalType
    let existingGoal: UserGoal?
    let onSave: (UserGoal) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMinutes: Int = 300

    private let presets: [Int] = [120, 180, 300, 420, 600]

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("Set \(goalType.displayName.lowercased()) goal")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(GraftColors.textPrimary)

                        Text("How much time do you want to practice?")
                            .font(.system(size: 14))
                            .foregroundColor(GraftColors.textSecondary)
                    }
                    .padding(.top, 8)

                    // Goal display
                    VStack(spacing: 4) {
                        Text(formattedGoal)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(GraftColors.accent)
                    }

                    // Presets
                    VStack(spacing: 12) {
                        Text("Quick set")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(GraftColors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(presets, id: \.self) { minutes in
                                Button {
                                    selectedMinutes = minutes
                                } label: {
                                    Text(formatMinutes(minutes))
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(selectedMinutes == minutes ? .white : GraftColors.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background {
                                            if selectedMinutes == minutes {
                                                LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .leading, endPoint: .trailing)
                                            } else {
                                                GraftColors.surface
                                            }
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }

                    Spacer()

                    Button {
                        saveGoal()
                    } label: {
                        Text("Set Goal")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Set Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(GraftColors.textSecondary)
                }
            }
            .onAppear {
                if let existing = existingGoal {
                    selectedMinutes = existing.targetMinutes
                } else {
                    selectedMinutes = goalType == .weekly ? 300 : 1200
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var formattedGoal: String {
        formatMinutes(selectedMinutes)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        }
        return "\(mins)m"
    }

    private func saveGoal() {
        let calendar = Calendar.current
        let now = Date()

        let (periodStart, periodEnd): (Date, Date)
        if goalType == .weekly {
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
            periodStart = weekStart
            periodEnd = weekEnd
        } else {
            let components = calendar.dateComponents([.year, .month], from: now)
            let monthStart = calendar.date(from: components) ?? now
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) ?? now
            periodStart = monthStart
            periodEnd = monthEnd
        }

        var goal = UserGoal(
            id: existingGoal?.id,
            type: goalType,
            targetMinutes: selectedMinutes,
            currentMinutes: existingGoal?.currentMinutes ?? 0,
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        DatabaseService.shared.saveGoal(&goal)
        onSave(goal)
        dismiss()
    }
}
