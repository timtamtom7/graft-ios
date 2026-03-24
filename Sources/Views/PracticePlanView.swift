import SwiftUI

struct PracticePlanView: View {
    let skills: [Skill]

    @Environment(\.dismiss) private var dismiss
    @State private var plans: [PracticePlan] = []
    @State private var showNewPlan: Bool = false
    @State private var showEditPlan: Bool = false
    @State private var selectedPlan: PracticePlan?

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()
                contentView
            }
            .navigationTitle("Practice Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(GraftColors.accent)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showNewPlan = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(GraftColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showNewPlan) {
                NewPlanSheet(skills: skills) { loadPlans() }
            }
            .sheet(isPresented: $showEditPlan) {
                if let plan = selectedPlan {
                    NewPlanSheet(skills: skills, editingPlan: plan) { loadPlans() }
                }
            }
            .onAppear { loadPlans() }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if plans.isEmpty {
                    emptyStateView
                } else {
                    upcomingSection
                    completedSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 60)
            emptyIcon
            emptyText
            Spacer()
        }
    }

    private var emptyIcon: some View {
        ZStack {
            Circle().fill(GraftColors.accent.opacity(0.1)).frame(width: 100, height: 100)
            Image(systemName: "calendar.badge.plus").font(.system(size: 40)).foregroundColor(GraftColors.accent)
        }
    }

    private var emptyText: some View {
        VStack(spacing: 8) {
            Text("No planned sessions")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(GraftColors.textPrimary)
            Text("Plan your practice sessions ahead of time to build a consistent routine.")
                .font(.system(size: 14))
                .foregroundColor(GraftColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var upcomingSection: some View {
        let upcoming = plans.filter { !$0.isCompleted }
        if !upcoming.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Upcoming")
                ForEach(upcoming) { plan in
                    upcomingCard(plan: plan)
                }
            }
        }
    }

    private func upcomingCard(plan: PracticePlan) -> some View {
        PlannedSessionCard(
            plan: plan,
            onComplete: { completePlan(plan) },
            onTap: {
                selectedPlan = plan
                showEditPlan = true
            },
            onDelete: { deletePlan(plan) }
        )
    }

    @ViewBuilder
    private var completedSection: some View {
        let completed = plans.filter { $0.isCompleted }
        if !completed.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Completed")
                ForEach(completed.prefix(5)) { plan in
                    PlannedSessionCard(plan: plan, onComplete: {}, onTap: {}, onDelete: {})
                        .opacity(0.6)
                }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(GraftColors.textSecondary)
            .textCase(.uppercase)
            .tracking(1.2)
    }

    private func loadPlans() { plans = DatabaseService.shared.getAllPlans() }
    private func completePlan(_ plan: PracticePlan) {
        guard let id = plan.id else { return }
        DatabaseService.shared.markPlanCompleted(id: id)
        loadPlans()
    }
    private func deletePlan(_ plan: PracticePlan) {
        guard let id = plan.id else { return }
        DatabaseService.shared.deletePlan(id: id)
        loadPlans()
    }
}

// MARK: - Planned Session Card

struct PlannedSessionCard: View {
    let plan: PracticePlan
    let onComplete: () -> Void
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(.plain)
        .contextMenu { contextMenuContent }
    }

    private var cardContent: some View {
        HStack(spacing: 14) {
            Text(plan.skillEmoji)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(GraftColors.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(plan.skillName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(GraftColors.textPrimary)
                timeLabel
            }

            Spacer()
            completionIndicator
        }
        .padding(16)
        .background(GraftColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(cardOverlay)
    }

    private var timeLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock").font(.system(size: 10))
            Text(formattedTime).font(.system(size: 12))
            Text("·").font(.system(size: 12))
            Image(systemName: "timer").font(.system(size: 10))
            Text("\(plan.durationMinutes)m").font(.system(size: 12))
        }
        .foregroundColor(GraftColors.textSecondary)
    }

    @ViewBuilder
    private var completionIndicator: some View {
        if !plan.isCompleted {
            Button { onComplete() } label: {
                Image(systemName: "checkmark.circle").font(.system(size: 22)).foregroundColor(GraftColors.accent)
            }
            .buttonStyle(.plain)
        } else {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 22)).foregroundColor(GraftColors.success)
        }
    }

    private var cardOverlay: some View {
        RoundedRectangle(cornerRadius: 14)
            .strokeBorder(plan.isCompleted ? Color.clear : GraftColors.accent.opacity(0.2), lineWidth: 1)
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        if !plan.isCompleted {
            Button { onComplete() } label: { Label("Mark Complete", systemImage: "checkmark.circle") }
        }
        Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(plan.scheduledAt) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if calendar.isDateInTomorrow(plan.scheduledAt) {
            formatter.dateFormat = "'Tomorrow at' h:mm a"
        } else {
            formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
        }
        return formatter.string(from: plan.scheduledAt)
    }
}

// MARK: - New Plan Sheet

struct NewPlanSheet: View {
    let skills: [Skill]
    var editingPlan: PracticePlan?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSkill: Skill?
    @State private var selectedDate: Date = Date()
    @State private var selectedDuration: Int = 30
    private let durations: [Int] = [15, 25, 30, 45, 60, 90]

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()
                VStack(spacing: 28) {
                    skillSection
                    dateSection
                    durationSection
                    Spacer()
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .navigationTitle(editingPlan != nil ? "Edit Plan" : "Plan a Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(GraftColors.textSecondary)
                }
            }
            .onAppear { initState() }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var skillSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelText("Skill")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(skills) { skill in skillPill(skill: skill) }
                }
            }
        }
    }

    private func skillPill(skill: Skill) -> some View {
        let isSelected = selectedSkill?.id == skill.id
        return Button {
            selectedSkill = skill
        } label: {
            HStack(spacing: 6) {
                Text(skill.emoji).font(.system(size: 14))
                Text(skill.name).font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : GraftColors.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .leading, endPoint: .trailing)
                } else {
                    LinearGradient(colors: [GraftColors.surface], startPoint: .leading, endPoint: .trailing)
                }
            }
            .clipShape(Capsule())
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelText("When")
            DatePicker("Scheduled Time", selection: $selectedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .tint(GraftColors.accent)
                .colorScheme(.dark)
                .padding(12)
                .background(GraftColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelText("Duration")
            HStack(spacing: 10) {
                ForEach(durations, id: \.self) { duration in durationPill(duration) }
            }
        }
    }

    private func durationPill(_ duration: Int) -> some View {
        let isSelected = selectedDuration == duration
        return Button {
            selectedDuration = duration
        } label: {
            Text("\(duration)m")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(isSelected ? .white : GraftColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    if isSelected {
                        LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .leading, endPoint: .trailing)
                    } else {
                        Rectangle().fill(GraftColors.surface)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var saveButton: some View {
        Button {
            savePlan()
        } label: {
            Text(editingPlan != nil ? "Update Plan" : "Schedule Session")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(selectedSkill == nil)
    }

    private func labelText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(GraftColors.textSecondary)
            .textCase(.uppercase)
            .tracking(1.2)
    }

    private func initState() {
        if let editing = editingPlan {
            selectedSkill = skills.first { $0.id == editing.skillId }
            selectedDate = editing.scheduledAt
            selectedDuration = editing.durationMinutes
        } else if let first = skills.first {
            selectedSkill = first
        }
    }

    private func savePlan() {
        guard let skill = selectedSkill else { return }
        if var editing = editingPlan {
            editing.scheduledAt = selectedDate
            editing.durationMinutes = selectedDuration
            DatabaseService.shared.savePlan(&editing)
        } else {
            var plan = PracticePlan(
                skillId: skill.id ?? 0,
                skillName: skill.name,
                skillEmoji: skill.emoji,
                scheduledAt: selectedDate,
                durationMinutes: selectedDuration
            )
            DatabaseService.shared.savePlan(&plan)
        }
        onSave()
        dismiss()
    }
}
