import SwiftUI

struct MacContentView: View {
    @StateObject private var viewModel = MacMainViewModel()
    @State private var selectedSkillId: Int64?
    @State private var showLogSession = false
    @State private var showSettings = false
    @State private var showMonthStats = false

    private var selectedSkill: Skill? {
        viewModel.skills.first { $0.id == selectedSkillId }
    }

    var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            detailView
        }
        .frame(minWidth: 900, minHeight: 620)
        .background(GraftColors.background)
        .task {
            viewModel.loadSkills()
            selectedSkillId = viewModel.activeSkill?.id
        }
        .sheet(isPresented: $showLogSession) {
            if let skill = selectedSkill {
                MacLogSessionSheet(skillId: skill.id ?? 0) {
                    Task { viewModel.refresh() }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            MacSettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showMonthStats) {
            if let skill = selectedSkill {
                MacMonthStatsView(skill: skill)
            }
        }
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Logo / header
            HStack(spacing: 10) {
                Text("📒")
                    .font(.title)
                Text("Graft")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(GraftColors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(GraftColors.surface)

            Divider()
                .background(GraftColors.surfaceRaised)

            List(selection: $selectedSkillId) {
                Section {
                    ForEach(viewModel.skills) { skill in
                        HStack(spacing: 10) {
                            Text(skill.emoji)
                                .font(.title3)
                            Text(skill.name)
                                .foregroundColor(GraftColors.textPrimary)
                            Spacer()
                            if skill.id == viewModel.activeSkill?.id {
                                Circle()
                                    .fill(GraftColors.accent)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSkillId = skill.id
                        }
                        .listRowBackground(
                            selectedSkillId == skill.id
                                ? GraftColors.surfaceRaised
                                : GraftColors.background
                        )
                    }
                } header: {
                    Text("Skills")
                        .font(.caption)
                        .foregroundColor(GraftColors.textSecondary)
                        .textCase(.uppercase)
                }

                Section {
                    Button {
                        showMonthStats = true
                    } label: {
                        Label("Monthly Stats", systemImage: "calendar")
                            .foregroundColor(GraftColors.textSecondary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                            .foregroundColor(GraftColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Tools")
                        .font(.caption)
                        .foregroundColor(GraftColors.textSecondary)
                        .textCase(.uppercase)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(GraftColors.background)
            .frame(minWidth: 200, idealWidth: 220, maxWidth: 280)

            Divider()
                .background(GraftColors.surfaceRaised)

            // Streak footer
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(viewModel.currentStreak) day streak")
                    .font(.caption)
                    .foregroundColor(GraftColors.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(GraftColors.surface)
        }
        .frame(minWidth: 200, idealWidth: 220, maxWidth: 280)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        if let skill = selectedSkill {
            MacSkillDetailView(
                skill: skill,
                onLogSession: { showLogSession = true },
                onViewMonth: { showMonthStats = true }
            )
        } else {
            VStack(spacing: 16) {
                Image(systemName: "book.fill")
                    .font(.system(size: 56))
                    .foregroundColor(GraftColors.accentMuted)
                Text("Select a Skill")
                    .font(.title2.bold())
                    .foregroundColor(GraftColors.textPrimary)
                Text("Choose a skill from the sidebar to start practicing.")
                    .font(.subheadline)
                    .foregroundColor(GraftColors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(GraftColors.background)
        }
    }
}

// MARK: - View Model

@MainActor
final class MacMainViewModel: ObservableObject {
    @Published var skills: [Skill] = []
    @Published var activeSkill: Skill?

    var currentStreak: Int {
        guard let skill = activeSkill else { return 0 }
        let sessions = DatabaseService.shared.getAllSessions(for: skill.id ?? 0)
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

    func loadSkills() {
        skills = DatabaseService.shared.getAllSkills()
        activeSkill = skills.first(where: { $0.isActive }) ?? skills.first
        if skills.isEmpty {
            skills = [
                Skill(id: 1, name: "Piano", emoji: "🎹", isActive: true),
                Skill(id: 2, name: "Guitar", emoji: "🎸", isActive: false),
                Skill(id: 3, name: "Coding", emoji: "💻", isActive: false),
            ]
            activeSkill = skills.first
        }
    }

    func refresh() {
        loadSkills()
    }
}
