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
    @State private var showSessionHistory: Bool = false
    @State private var showSettings: Bool = false
    @State private var showTeacher: Bool = false
    @State private var showStudentAssignments: Bool = false
    @State private var currentTier: SubscriptionTier = .free

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
                            HapticFeedback.light()
                            showPracticeTimer = true
                        } label: {
                            Image(systemName: "timer")
                                .font(.system(size: Theme.IconSize.medium))
                                .foregroundColor(GraftColors.accent)
                        }
                        .accessibilityLabel("Practice Timer")

                        Button {
                            HapticFeedback.light()
                            showAnalytics = true
                        } label: {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: Theme.IconSize.medium))
                                .foregroundColor(GraftColors.accent)
                        }
                        .accessibilityLabel("Analytics")

                        Button {
                            HapticFeedback.light()
                            showPracticePlan = true
                        } label: {
                            Image(systemName: "calendar")
                                .font(.system(size: Theme.IconSize.medium))
                                .foregroundColor(GraftColors.accent)
                        }
                        .accessibilityLabel("Practice Plan")

                        Button {
                            HapticFeedback.light()
                            showPricing = true
                        } label: {
                            Image(systemName: "crown.fill")
                                .font(.system(size: Theme.IconSize.medium))
                                .foregroundColor(GraftColors.accent)
                        }
                        .accessibilityLabel("Pricing and Subscription")

                        Button {
                            HapticFeedback.light()
                            showTeacher = true
                        } label: {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: Theme.IconSize.medium))
                                .foregroundColor(GraftColors.accent)
                        }
                        .accessibilityLabel("Teacher View")

                        Button {
                            HapticFeedback.light()
                            showStudentAssignments = true
                        } label: {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.system(size: Theme.IconSize.medium))
                                .foregroundColor(GraftColors.accent)
                        }
                        .accessibilityLabel("Student Assignments")

                        Button {
                            HapticFeedback.light()
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: Theme.IconSize.medium))
                                .foregroundColor(GraftColors.accent)
                        }
                        .accessibilityLabel("Settings")

                        Button {
                            HapticFeedback.light()
                            showSessionHistory = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: Theme.IconSize.medium))
                                .foregroundColor(GraftColors.accent)
                        }
                        .accessibilityLabel("Session History")
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
            .sheet(isPresented: $showSessionHistory) {
                SessionHistoryView(skills: skills.isEmpty ? (primarySkill.map { [$0] } ?? []) : skills)
            }
            .sheet(isPresented: $showTeacher) {
                TeacherView()
            }
            .sheet(isPresented: $showStudentAssignments) {
                StudentAssignmentsView()
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
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(skills) { skill in
                    Button {
                        HapticFeedback.selection()
                        primarySkill = skill
                        loadSkillData()
                    } label: {
                        HStack(spacing: 6) {
                            Text(skill.emoji)
                                .font(.system(size: Theme.FontSize.footnote))
                            Text(skill.name)
                                .font(.system(size: Theme.FontSize.footnote, weight: .medium))
                        }
                        .foregroundColor(primarySkill?.id == skill.id ? .white : GraftColors.textSecondary)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(
                            primarySkill?.id == skill.id
                                ? LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [GraftColors.surface], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel("\(skill.emoji) \(skill.name)")
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
        Button {
            HapticFeedback.light()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: Theme.IconSize.large))
                    .foregroundColor(GraftColors.accent)
                Text(label)
                    .font(.system(size: Theme.FontSize.caption2, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xl)
            .background(GraftColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        }
        .accessibilityLabel(label)
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
        currentTier = DatabaseService.shared.getCurrentTier()
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
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(skills.prefix(5)) { skill in
                let weekly = getWeeklyMinutes(for: skill)
                HStack(spacing: Theme.Spacing.sm) {
                    Text(skill.emoji)
                        .font(.system(size: Theme.FontSize.footnote))
                        .frame(width: 20)

                    Text(skill.name)
                        .font(.system(size: Theme.FontSize.caption, weight: .medium))
                        .foregroundColor(GraftColors.textPrimary)
                        .frame(width: 70, alignment: .leading)

                    GeometryReader { geometry in
                        let maxMinutes: CGFloat = 300
                        let barWidth = CGFloat(weekly) / maxMinutes * geometry.size.width

                        RoundedRectangle(cornerRadius: Theme.CornerRadius.xs)
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
                        .font(.system(size: Theme.FontSize.caption2, design: .monospaced))
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
