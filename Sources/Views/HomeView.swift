import SwiftUI

struct HomeView: View {
    @State private var skill: Skill?
    @State private var weeklySessions: [(date: Date, totalMinutes: Int)] = []
    @State private var monthlyTotalMinutes: Int = 0
    @State private var practiceDaysCount: Int = 0
    @State private var showLogSession: Bool = false
    @State private var showSkillPicker: Bool = false
    @State private var showMonthlyView: Bool = false
    @State private var showPricing: Bool = false
    @State private var showSessionError: Bool = false
    @State private var sessionErrorMessage: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                if let skill = skill {
                    ScrollView {
                        VStack(spacing: 24) {
                            skillCard(for: skill)
                            weekDotsSection(for: skill)
                            monthSummaryButton
                            changeSkillButton
                            upgradeButton
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                } else {
                    noSkillView
                }
            }
            .navigationTitle("Graft")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPricing = true
                    } label: {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundColor(GraftColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showLogSession) {
                LogSessionSheet(skillId: skill?.id ?? 0) {
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
            .sheet(isPresented: $showMonthlyView) {
                if let skill = skill {
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
            .onAppear {
                refreshData()
            }
        }
    }

    // MARK: - Subviews

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

                // Progress bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("This month")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(GraftColors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                        Spacer()
                        Text("\(Int(weeklyProgress * 100))% of last week")
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
        // Compare to a baseline of 5 hours (300 min)
        return min(Double(thisWeek) / 300.0, 1.0)
    }

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

    private var monthSummaryButton: some View {
        Button {
            showMonthlyView = true
        } label: {
            HStack {
                Text("Monthly View")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(GraftColors.textPrimary)
                Spacer()
                Image(systemName: "calendar")
                    .foregroundColor(GraftColors.accent)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(GraftColors.textSecondary)
            }
            .padding(16)
            .background(GraftColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var changeSkillButton: some View {
        Button {
            showSkillPicker = true
        } label: {
            Text("Change Skill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(GraftColors.textSecondary)
                .underline()
        }
    }

    private var upgradeButton: some View {
        Button {
            showPricing = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "crown")
                    .font(.system(size: 13))
                Text("Upgrade for more skills")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(GraftColors.accentMuted)
        }
    }

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
        skill = DatabaseService.shared.getActiveSkill()
        guard let skillId = skill?.id else {
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
