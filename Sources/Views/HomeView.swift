import SwiftUI

struct HomeView: View {
    @State private var skills: [Skill] = []
    @State private var primarySkill: Skill?
    @State private var weeklySessions: [(date: Date, totalMinutes: Int)] = []
    @State private var monthlyTotalMinutes: Int = 0
    @State private var practiceDaysCount: Int = 0
    @State private var showLogSession: Bool = false
    @State private var showSkillPicker: Bool = false
    @State private var showSkillManagement: Bool = false
    @State private var showMonthlyView: Bool = false
    @State private var showPricing: Bool = false
    @State private var showSessionError: Bool = false
    @State private var sessionErrorMessage: String = ""
    @State private var showPracticeTimer: Bool = false
    @State private var showAnalytics: Bool = false
    @State private var showPracticePlan: Bool = false
    @State private var showSettings: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                if primarySkill != nil || !skills.isEmpty {
                    mainContent
                } else {
                    noSkillView
                }
            }
            .navigationTitle("Graft")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !skills.isEmpty {
                        Button {
                            showSkillManagement = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("\(skills.count)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                Image(systemName: "book.fill")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(GraftColors.accent)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showPracticeTimer = true
                        } label: {
                            Image(systemName: "timer")
                                .font(.system(size: 14))
                                .foregroundColor(GraftColors.accent)
                        }

                        Button {
                            showAnalytics = true
                        } label: {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 14))
                                .foregroundColor(GraftColors.accent)
                        }

                        Button {
                            showPracticePlan = true
                        } label: {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundColor(GraftColors.accent)
                        }

                        Button {
                            showPricing = true
                        } label: {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundColor(GraftColors.accent)
                        }

                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 14))
                                .foregroundColor(GraftColors.accent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showLogSession) {
                LogSessionSheet(skillId: primarySkill?.id ?? 0) {
                    refreshData()
                } onError: { message in
                    sessionErrorMessage = message
                    showSessionError = true
                }
            }
            .sheet(isPresented: $showSkillPicker) {
                SkillPickerSheet {
                    refreshData()
                } onLimitReached: {
                    showPricing = true
                }
            }
            .sheet(isPresented: $showSkillManagement) {
                SkillManagementView(skills: skills) {
                    refreshData()
                }
            }
            .sheet(isPresented: $showMonthlyView) {
                if let skill = primarySkill {
                    MonthlyView(skill: skill)
                }
            }
            .sheet(isPresented: $showPricing) {
                PricingView()
            }
            .sheet(isPresented: $showSessionError) {
                SessionErrorView(
                    message: sessionErrorMessage,
                    onRetry: {
                        showSessionError = false
                        showLogSession = true
                    },
                    onDismiss: {
                        showSessionError = false
                    }
                )
            }
            .sheet(isPresented: $showPracticeTimer) {
                PracticeTimerView(skills: skills.isEmpty ? (primarySkill.map { [$0] } ?? []) : skills)
            }
            .sheet(isPresented: $showAnalytics) {
                AnalyticsView(skills: skills.isEmpty ? (primarySkill.map { [$0] } ?? []) : skills)
            }
            .sheet(isPresented: $showPracticePlan) {
                PracticePlanView(skills: skills.isEmpty ? (primarySkill.map { [$0] } ?? []) : skills)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                refreshData()
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                if skills.count > 1 {
                    skillTabsSection
                }

                if let skill = primarySkill {
                    skillCard(for: skill)
                    weekDotsSection(for: skill)
                    monthSummaryCard(for: skill)
                }

                quickActionsSection

                if skills.count > 1 {
                    skillComparisonPreview
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Skill Tabs

    private var skillTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(skills) { skill in
                    Button {
                        primarySkill = skill
                        loadSkillData()
                    } label: {
                        HStack(spacing: 6) {
                            Text(skill.emoji)
                                .font(.system(size: 14))
                            Text(skill.name)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(primarySkill?.id == skill.id ? .white : GraftColors.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            primarySkill?.id == skill.id
                                ? LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [GraftColors.surface], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Skill Card

    private func skillCard(for skill: Skill) -> some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    SkillIconGraphic(skill: skill.name, size: 56)
                        .frame(width: 56, height: 56)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Currently tracking")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(GraftColors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                        Text(skill.name)
                            .font(.system(size: 22, weight: .bold, design: .default))
                            .foregroundColor(GraftColors.textPrimary)
                    }
                }

                Divider()
                    .background(GraftColors.textSecondary.opacity(0.3))

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("This week")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(GraftColors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                        Spacer()
                        Text("\(Int(weeklyProgress * 100))% of goal")
                            .font(.system(size: 11))
                            .foregroundColor(GraftColors.textSecondary)
                    }

                    ProgressBarGraphic(progress: weeklyProgress, height: 8)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formattedMonthlyTime)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(GraftColors.textPrimary)
                        Text("this month")
                            .font(.system(size: 11))
                            .foregroundColor(GraftColors.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(practiceDaysCount)")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(GraftColors.accent)
                        Text("days practiced")
                            .font(.system(size: 11))
                            .foregroundColor(GraftColors.textSecondary)
                    }
                }

                Button {
                    showLogSession = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Log Session")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [GraftColors.accent, GraftColors.accentMuted],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(20)
        }
    }

    private var weeklyProgress: Double {
        guard !weeklySessions.isEmpty else { return 0 }
        let thisWeek = weeklySessions.reduce(0) { $0 + $1.totalMinutes }
        return min(Double(thisWeek) / 300.0, 1.0)
    }

    // MARK: - Week Dots

    private func weekDotsSection(for skill: Skill) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This week")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(GraftColors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)

            LiquidGlassCard {
                WeekDotsView(sessions: weeklySessions)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - Month Summary Card

    private func monthSummaryCard(for skill: Skill) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Overview")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(GraftColors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)

            LiquidGlassCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formattedMonthlyTime)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(GraftColors.textPrimary)
                        Text("this month")
                            .font(.system(size: 11))
                            .foregroundColor(GraftColors.textSecondary)
                    }

                    Spacer()

                    Button {
                        showMonthlyView = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Details")
                                .font(.system(size: 13, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(GraftColors.accent)
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(GraftColors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)

            HStack(spacing: 10) {
                quickActionButton(icon: "timer", label: "Timer") {
                    showPracticeTimer = true
                }
                quickActionButton(icon: "chart.line.uptrend.xyaxis", label: "Analytics") {
                    showAnalytics = true
                }
                quickActionButton(icon: "calendar.badge.plus", label: "Plan") {
                    showPracticePlan = true
                }
                quickActionButton(icon: "calendar", label: "Monthly") {
                    showMonthlyView = true
                }
            }
        }
    }

    private func quickActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(GraftColors.accent)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(GraftColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Skill Comparison Preview

    private var skillComparisonPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This week")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)
                Spacer()
                Button {
                    showSkillManagement = true
                } label: {
                    Text("Manage")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(GraftColors.accent)
                }
            }

            LiquidGlassCard {
                SkillComparisonPreview(skills: skills)
                    .padding(16)
            }
        }
    }

    // MARK: - No Skill

    private var noSkillView: some View {
        VStack(spacing: 20) {
            HourglassGraphic(size: 80)
                .frame(width: 80, height: 80)

            Text("No skill selected")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(GraftColors.textPrimary)

            Text("Pick something you've been meaning to practice.")
                .font(.system(size: 14))
                .foregroundColor(GraftColors.textSecondary)

            Button {
                showSkillPicker = true
            } label: {
                Text("Choose Skill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [GraftColors.accent, GraftColors.accentMuted],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Helpers

    private var formattedMonthlyTime: String {
        let hours = monthlyTotalMinutes / 60
        let minutes = monthlyTotalMinutes % 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    private func refreshData() {
        skills = DatabaseService.shared.getActiveSkills()
        primarySkill = skills.first
        loadSkillData()
        WidgetDataManager.shared.refreshWidgetData()
    }

    private func loadSkillData() {
        guard let skillId = primarySkill?.id else {
            weeklySessions = []
            monthlyTotalMinutes = 0
            practiceDaysCount = 0
            return
        }

        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else { return }

        weeklySessions = DatabaseService.shared.getWeeklySessions(for: skillId, weekStart: weekStart)
        monthlyTotalMinutes = DatabaseService.shared.getMonthlyTotalMinutes(for: skillId, month: today)
        practiceDaysCount = DatabaseService.shared.getPracticeDaysCount(for: skillId, month: today)
    }
}

// MARK: - Skill Comparison Preview

struct SkillComparisonPreview: View {
    let skills: [Skill]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(skills.prefix(5)) { skill in
                let weekly = getWeeklyMinutes(for: skill)
                HStack(spacing: 10) {
                    Text(skill.emoji)
                        .font(.system(size: 14))
                        .frame(width: 20)

                    Text(skill.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(GraftColors.textPrimary)
                        .frame(width: 70, alignment: .leading)

                    GeometryReader { geometry in
                        let maxMinutes: CGFloat = 300
                        let barWidth = CGFloat(weekly) / maxMinutes * geometry.size.width

                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [GraftColors.accent.opacity(0.6), GraftColors.accentMuted.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(barWidth, 3), height: 10)
                    }
                    .frame(height: 10)

                    Text(formatMinutes(weekly))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(GraftColors.textSecondary)
                        .frame(width: 35, alignment: .trailing)
                }
            }
        }
    }

    private func getWeeklyMinutes(for skill: Skill) -> Int {
        guard let skillId = skill.id else { return 0 }
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else { return 0 }
        let sessions = DatabaseService.shared.getWeeklySessions(for: skillId, weekStart: weekStart)
        return sessions.reduce(0) { $0 + $1.totalMinutes }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return mins > 0 ? "\(hours)h\(mins)" : "\(hours)h"
        }
        return "\(mins)m"
    }
}
