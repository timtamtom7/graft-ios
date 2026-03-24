import SwiftUI

struct SkillManagementView: View {
    let skills: [Skill]
    let onSkillsChanged: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showAddSkill: Bool = false
    @State private var showLimitReached: Bool = false
    @State private var showRemoveConfirm: Bool = false
    @State private var skillToRemove: Skill?

    private let maxMasterSkills = 5

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Active skills section
                        if !activeSkills.isEmpty {
                            activeSkillsSection
                        }

                        // All skills section
                        if skills.count > activeSkills.count {
                            allSkillsSection
                        }

                        addSkillSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("My Skills")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(GraftColors.accent)
                }
            }
            .sheet(isPresented: $showAddSkill) {
                AddSkillSheet(
                    canAdd: canAddMore,
                    skills: skills
                ) { name, emoji in
                    addSkill(name: name, emoji: emoji)
                } onLimitReached: {
                    showLimitReached = true
                }
            }
            .sheet(isPresented: $showLimitReached) {
                SkillLimitReachedView(onDismiss: {
                    showLimitReached = false
                })
            }
            .sheet(isPresented: $showRemoveConfirm) {
                if let skill = skillToRemove {
                    ConfirmRemoveSkillView(
                        skill: skill,
                        onConfirm: {
                            removeSkill(skill)
                            showRemoveConfirm = false
                        },
                        onCancel: {
                            showRemoveConfirm = false
                        }
                    )
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Active Skills Section

    private var activeSkillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tracking")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Spacer()

                Text("\(activeSkills.count)/\(maxMasterSkills)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(GraftColors.accent)
            }

            ForEach(activeSkills) { skill in
                ActiveSkillRow(
                    skill: skill,
                    weeklyMinutes: getWeeklyMinutes(for: skill),
                    monthlyMinutes: getMonthlyMinutes(for: skill),
                    onDeactivate: {
                        skillToRemove = skill
                        showRemoveConfirm = true
                    }
                )
            }
        }
    }

    // MARK: - All Skills Section

    private var allSkillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inactive Skills")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(GraftColors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)

            ForEach(inactiveSkills) { skill in
                InactiveSkillRow(skill: skill) {
                    reactivateSkill(skill)
                }
            }
        }
    }

    // MARK: - Add Skill Section

    private var addSkillSection: some View {
        VStack(spacing: 12) {
            Button {
                if canAddMore {
                    showAddSkill = true
                } else {
                    showLimitReached = true
                }
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Skill")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if !canAddMore {
                Text("Upgrade to Master tier for unlimited skills")
                    .font(.system(size: 12))
                    .foregroundColor(GraftColors.textSecondary)
            }
        }
    }

    // MARK: - Helpers

    private var activeSkills: [Skill] {
        skills.filter { $0.isActive }
    }

    private var inactiveSkills: [Skill] {
        skills.filter { !$0.isActive }
    }

    private var canAddMore: Bool {
        activeSkills.count < maxMasterSkills
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

    private func getMonthlyMinutes(for skill: Skill) -> Int {
        guard let skillId = skill.id else { return 0 }
        return DatabaseService.shared.getMonthlyTotalMinutes(for: skillId, month: Date())
    }

    private func addSkill(name: String, emoji: String) {
        var skill = Skill(name: name, emoji: emoji, isActive: true)
        DatabaseService.shared.saveSkill(&skill)
        onSkillsChanged()
    }

    private func reactivateSkill(_ skill: Skill) {
        guard let skillId = skill.id, canAddMore else {
            showLimitReached = true
            return
        }
        DatabaseService.shared.activateSkill(id: skillId)
        onSkillsChanged()
    }

    private func removeSkill(_ skill: Skill) {
        guard let skillId = skill.id else { return }
        DatabaseService.shared.deactivateSkill(id: skillId)
        onSkillsChanged()
    }
}

// MARK: - Active Skill Row

struct ActiveSkillRow: View {
    let skill: Skill
    let weeklyMinutes: Int
    let monthlyMinutes: Int
    let onDeactivate: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(skill.emoji)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(GraftColors.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(skill.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(GraftColors.textPrimary)

                HStack(spacing: 12) {
                    Label(formattedWeeklyTime, systemImage: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(GraftColors.textSecondary)

                    Label(formattedMonthlyTime, systemImage: "chart.bar")
                        .font(.system(size: 11))
                        .foregroundColor(GraftColors.textSecondary)
                }
            }

            Spacer()

            Button {
                onDeactivate()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(GraftColors.textSecondary.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(GraftColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var formattedWeeklyTime: String {
        let hours = weeklyMinutes / 60
        let minutes = weeklyMinutes % 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    private var formattedMonthlyTime: String {
        let hours = monthlyMinutes / 60
        let minutes = monthlyMinutes % 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - Inactive Skill Row

struct InactiveSkillRow: View {
    let skill: Skill
    let onActivate: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(skill.emoji)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(GraftColors.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .opacity(0.5)

            Text(skill.name)
                .font(.system(size: 14))
                .foregroundColor(GraftColors.textSecondary)

            Spacer()

            Button {
                onActivate()
            } label: {
                Text("Re-add")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(GraftColors.accent)
            }
        }
        .padding(14)
        .background(GraftColors.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Add Skill Sheet

struct AddSkillSheet: View {
    let canAdd: Bool
    let skills: [Skill]
    let onAdd: (String, String) -> Void
    let onLimitReached: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var customSkillName: String = ""
    @State private var customSkillEmoji: String = "🎯"
    @State private var searchText: String = ""

    private let commonSkills: [(name: String, emoji: String)] = [
        ("Guitar", "🎸"), ("Piano", "🎹"), ("Coding", "💻"), ("Language", "🗣"),
        ("Chess", "♟️"), ("Drawing", "🎨"), ("Basketball", "🏀"), ("Tennis", "🎾"),
        ("Running", "🏃"), ("Reading", "📚"), ("Writing", "✍️"), ("Cooking", "🍳"),
        ("Photography", "📷"), ("Yoga", "🧘"), ("Singing", "🎤"), ("Drums", "🥁"),
        ("Woodworking", "🪚"), ("Gardening", "🌱"), ("Calligraphy", "✒️"), ("Meditation", "🧠")
    ]

    private var filteredSkills: [(name: String, emoji: String)] {
        if searchText.isEmpty {
            return commonSkills
        }
        return commonSkills.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var existingSkillNames: Set<String> {
        Set(skills.map { $0.name.lowercased() })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search
                    TextField("Search or add custom...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15))
                        .foregroundColor(GraftColors.textPrimary)
                        .padding(14)
                        .background(GraftColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    ScrollView {
                        LazyVStack(spacing: 8) {
                            // Custom add
                            if !searchText.isEmpty && !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                                let trimmed = searchText.trimmingCharacters(in: .whitespaces)
                                let notExists = !existingSkillNames.contains(trimmed.lowercased())

                                if notExists {
                                    Button {
                                        onAdd(trimmed, "🎯")
                                        dismiss()
                                    } label: {
                                        HStack(spacing: 14) {
                                            Text("🎯")
                                                .font(.system(size: 28))
                                                .frame(width: 44, height: 44)
                                                .background(GraftColors.surface)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Add \"\(trimmed)\"")
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(GraftColors.accent)
                                                Text("Create custom skill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(GraftColors.textSecondary)
                                            }

                                            Spacer()

                                            Image(systemName: "plus.circle")
                                                .foregroundColor(GraftColors.accent)
                                        }
                                        .padding(14)
                                        .background(GraftColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }

                            ForEach(filteredSkills, id: \.name) { skill in
                                let alreadyAdded = existingSkillNames.contains(skill.name.lowercased())
                                skillRow(name: skill.name, emoji: skill.emoji, alreadyAdded: alreadyAdded) {
                                    if canAdd {
                                        onAdd(skill.name, skill.emoji)
                                        dismiss()
                                    } else {
                                        onLimitReached()
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Add Skill")
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
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func skillRow(name: String, emoji: String, alreadyAdded: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text(emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(GraftColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(alreadyAdded ? GraftColors.textSecondary : GraftColors.textPrimary)

                Spacer()

                if alreadyAdded {
                    Text("Added")
                        .font(.system(size: 12))
                        .foregroundColor(GraftColors.textSecondary)
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundColor(GraftColors.accent)
                }
            }
            .padding(14)
            .background(GraftColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(alreadyAdded ? 0.6 : 1.0)
        }
        .disabled(alreadyAdded)
        .padding(.horizontal, 20)
    }
}

// MARK: - Skill Limit Reached View

struct SkillLimitReachedView: View {
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(GraftColors.accent.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 36))
                            .foregroundColor(GraftColors.accent)
                    }

                    VStack(spacing: 8) {
                        Text("Skill limit reached")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(GraftColors.textPrimary)

                        Text("You can track up to 5 skills with Master tier. Upgrade or remove a skill to add more.")
                            .font(.system(size: 14))
                            .foregroundColor(GraftColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 32)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Text("OK")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Limit Reached")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(GraftColors.textSecondary)
                    }
                }
            })
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Confirm Remove Skill View

struct ConfirmRemoveSkillView: View {
    let skill: Skill
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    Text(skill.emoji)
                        .font(.system(size: 48))
                        .frame(width: 80, height: 80)
                        .background(GraftColors.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(spacing: 8) {
                        Text("Stop tracking \(skill.name)?")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(GraftColors.textPrimary)

                        Text("Your practice history will be preserved, but \(skill.name) will be removed from your active skills.")
                            .font(.system(size: 14))
                            .foregroundColor(GraftColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 32)
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        Button {
                            onConfirm()
                            dismiss()
                        } label: {
                            Text("Remove Skill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(GraftColors.accent.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                        }

                        Button {
                            onCancel()
                            dismiss()
                        } label: {
                            Text("Keep Skill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(GraftColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Remove Skill")
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
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
