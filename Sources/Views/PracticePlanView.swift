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

                ScrollView {
                    VStack(spacing: 20) {
                        if plans.isEmpty {
                            emptyState
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
            .navigationTitle("Practice Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(GraftColors.accent)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewPlan = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(GraftColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showNewPlan) {
                NewPlanSheet(skills: skills) {
                    loadPlans()
                }
            }
            .sheet(isPresented: $showEditPlan) {
                if let plan = selectedPlan {
                    NewPlanSheet(skills: skills, editingPlan: plan) {
                        loadPlans()
                    }
                }
            }
            .onAppear {
                loadPlans()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 60)

            ZStack {
                Circle()
                    .fill(GraftColors.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(GraftColors.accent)
            }

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

            Button {
                showNewPlan = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Plan a Session")
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
            .padding(.horizontal, 48)
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Upcoming Section

    @ViewBuilder
    private var upcomingSection: some View {
        let upcoming = plans.filter { !$0.isCompleted }
        if !upcoming.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Upcoming")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)

                ForEach(upcoming) { plan in
                    PlannedSessionCard(
                        plan: plan,
                        onComplete: {
                            completePlan(plan)
                        },
                        onTap: {
                            selectedPlan = plan
                            showEditPlan = true
                        },
                        onDelete: {
                            deletePlan(plan)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Completed Section

    private var completedSection: some View {
        let completed = plans.filter { $0.isCompleted }
        return Group {
            if !completed.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Completed")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(GraftColors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.2)

                    ForEach(completed.prefix(5)) { plan in
                        PlannedSessionCard(
                            plan: plan,
                            onComplete: {},
                            onTap: {},
                            onDelete: {}
                        )
                        .opacity(0.6)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func loadPlans() {
        plans = DatabaseService.shared.getAllPlans()
    }

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
            HStack(spacing: 14) {
                // Skill emoji
                Text(plan.skillEmoji)
                    .font(.system(size: 24))
                    .frame(width: 44, height: 44)
                    .background(GraftColors.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.skillName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(GraftColors.textPrimary)

                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(formattedTime)
                            .font(.system(size: 12))

                        Text("·")
                            .font(.system(size: 12))

                        Image(systemName: "timer")
                            .font(.system(size: 10))
                        Text("\(plan.durationMinutes)m")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(GraftColors.textSecondary)
                }

                Spacer()

                if !plan.isCompleted {
                    Button {
                        onComplete()
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 22))
                            .foregroundColor(GraftColors.accent)
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(GraftColors.success)
                }
            }
            .padding(16)
            .background(GraftColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(plan.isCompleted ? Color.clear : GraftColors.accent.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !plan.isCompleted {
                Button {
                    onComplete()
                } label: {
                    Label("Mark Complete", systemImage: "checkmark.circle")
                }
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
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
                    // Skill selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Skill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(GraftColors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(skills) { skill in
                                    Button {
                                        selectedSkill = skill
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(skill.emoji)
                                                .font(.system(size: 14))
                                            Text(skill.name)
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                        .foregroundColor(selectedSkill?.id == skill.id ? .white : GraftColors.textSecondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedSkill?.id == skill.id
                                                ? LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .leading, endPoint: .trailing)
                                                : LinearGradient(colors: [GraftColors.surface], startPoint: .leading, endPoint: .trailing)
                                        )
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    // Date & Time
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(GraftColors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)

                        DatePicker(
                            "Scheduled Time",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .tint(GraftColors.accent)
                        .colorScheme(.dark)
                        .padding(12)
                        .background(GraftColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Duration
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Duration")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(GraftColors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)

                        HStack(spacing: 10) {
                            ForEach(durations, id: \.self) { duration in
                                Button {
                                    selectedDuration = duration
                                } label: {
                                    Text("\(duration)m")
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                        .foregroundColor(selectedDuration == duration ? .white : GraftColors.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background {
                                            if selectedDuration == duration {
                                                LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .leading, endPoint: .trailing)
                                            } else {
                                                Rectangle().fill(GraftColors.surface)
                                            }
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }

                    Spacer()

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
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .navigationTitle(editingPlan != nil ? "Edit Plan" : "Plan a Session")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(GraftColors.textSecondary)
                }
            }
            .onAppear {
                if let editing = editingPlan {
                    selectedSkill = skills.first { $0.id == editing.skillId }
                    selectedDate = editing.scheduledAt
                    selectedDuration = editing.durationMinutes
                } else if let first = skills.first {
                    selectedSkill = first
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
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
