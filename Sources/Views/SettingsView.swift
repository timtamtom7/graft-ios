import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showExport: Bool = false
    @State private var reminderEnabled: Bool = false
    @State private var reminderHour: Int = 9
    @State private var reminderMinute: Int = 0
    @State private var showTimePicker: Bool = false
    @State private var notificationStatus: String = "Checking..."
    @State private var primarySkill: Skill?

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        remindersSection
                        // Export Section
                        LiquidGlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Data")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(GraftColors.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(1.2)

                                Button {
                                    showExport = true
                                } label: {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 16))
                                            .foregroundColor(GraftColors.accent)
                                            .frame(width: 28)

                                        Text("Export & Share")
                                            .font(.system(size: 15))
                                            .foregroundColor(GraftColors.textPrimary)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(GraftColors.textSecondary.opacity(0.5))
                                    }
                                }
                            }
                            .padding(20)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // About Section
                        LiquidGlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("About Graft")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(GraftColors.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(1.2)

                                Text("Put in the work.")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(GraftColors.textPrimary)

                                Text("Graft is a simple practice tracker for people learning a skill. No streaks, no gamification — just honest tracking of the time you put in.")
                                    .font(.system(size: 14))
                                    .foregroundColor(GraftColors.textSecondary)
                                    .lineSpacing(4)
                            }
                            .padding(20)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        LiquidGlassCard {
                            HStack {
                                Text("Version")
                                    .font(.system(size: 15))
                                    .foregroundColor(GraftColors.textPrimary)
                                Spacer()
                                Text("1.0.0")
                                    .font(.system(size: 15))
                                    .foregroundColor(GraftColors.textSecondary)
                            }
                            .padding(20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
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
            .sheet(isPresented: $showExport) {
                ExportView()
            }
            .sheet(isPresented: $showTimePicker) {
                ReminderTimePickerSheet(
                    hour: $reminderHour,
                    minute: $reminderMinute,
                    skillName: primarySkill?.name ?? "your skill"
                ) {
                    Task {
                        await saveReminderSettings()
                    }
                }
            }
            .onAppear { loadSettings() }
        }
    }

    // MARK: - Reminders Section

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminders")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(GraftColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)

            LiquidGlassCard {
                VStack(spacing: 0) {
                    // Enable toggle
                    reminderToggleRow

                    if reminderEnabled {
                        Divider().background(GraftColors.textSecondary.opacity(0.2))

                        // Time picker row
                        reminderTimeRow

                        Divider().background(GraftColors.textSecondary.opacity(0.2))

                        // AI suggestion row
                        aiSuggestionRow
                    }

                    Divider().background(GraftColors.textSecondary.opacity(0.2))

                    // Notification status
                    notificationStatusRow
                }
                .padding(20)
            }
        }
    }

    private var reminderToggleRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Daily Reminder")
                    .font(.system(size: Theme.FontSize.subheadline))
                    .foregroundColor(GraftColors.textPrimary)
                Text("Get notified when it's time to practice")
                    .font(.system(size: Theme.FontSize.caption))
                    .foregroundColor(GraftColors.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $reminderEnabled)
                .tint(GraftColors.accent)
                .onChange(of: reminderEnabled) { _, newValue in
                    HapticFeedback.selection()
                    Task {
                        await toggleReminder(enabled: newValue)
                    }
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily reminder, \(reminderEnabled ? "enabled" : "disabled")")
    }

    private var reminderTimeRow: some View {
        Button {
            HapticFeedback.light()
            showTimePicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text("Reminder Time")
                        .font(.system(size: Theme.FontSize.subheadline))
                        .foregroundColor(GraftColors.textPrimary)
                    Text("We'll send you a notification at this time")
                        .font(.system(size: Theme.FontSize.caption))
                        .foregroundColor(GraftColors.textSecondary)
                }
                Spacer()
                Text(formattedReminderTime)
                    .font(.system(size: Theme.FontSize.subheadline, weight: .medium, design: .monospaced))
                    .foregroundColor(GraftColors.accent)
                Image(systemName: "chevron.right")
                    .font(.system(size: Theme.FontSize.caption))
                    .foregroundColor(GraftColors.textSecondary.opacity(0.5))
            }
        }
        .accessibilityLabel("Reminder time, \(formattedReminderTime). Tap to change.")
    }

    private var aiSuggestionRow: some View {
        Button {
            HapticFeedback.medium()
            Task {
                await applyAISuggestedTime()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text("Use AI Suggestion")
                        .font(.system(size: Theme.FontSize.subheadline))
                        .foregroundColor(GraftColors.textPrimary)
                    if let skill = primarySkill {
                        Text("Set to optimal time for \(skill.name) (\(aiSuggestedTimeString))")
                            .font(.system(size: Theme.FontSize.caption))
                            .foregroundColor(GraftColors.textSecondary)
                    } else {
                        Text("Based on your practice patterns")
                            .font(.system(size: Theme.FontSize.caption))
                            .foregroundColor(GraftColors.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: Theme.IconSize.medium))
                    .foregroundColor(GraftColors.accent)
            }
        }
        .disabled(primarySkill == nil)
        .opacity(primarySkill == nil ? 0.5 : 1.0)
        .accessibilityLabel("Use AI suggested reminder time")
    }

    private var notificationStatusRow: some View {
        HStack {
            Image(systemName: notificationIcon)
                .font(.system(size: 12))
                .foregroundColor(notificationStatusColor)

            Text(notificationStatus)
                .font(.system(size: 12))
                .foregroundColor(GraftColors.textSecondary)

            Spacer()
        }
    }

    private var formattedReminderTime: String {
        ReminderService.shared.formattedReminderTime
    }

    private var aiSuggestedTimeString: String {
        if let skill = primarySkill, let skillId = skill.id,
           let suggested = ReminderService.shared.aiSuggestedTime(for: skillId) {
            var components = DateComponents()
            components.hour = suggested.hour
            components.minute = suggested.minute
            guard let date = Calendar.current.date(from: components) else { return "" }
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        return "Not available"
    }

    private var notificationIcon: String {
        switch notificationStatus {
        case "Authorized": return "bell.badge.fill"
        case "Denied": return "bell.slash.fill"
        case "Not Determined": return "bell"
        default: return "bell"
        }
    }

    private var notificationStatusColor: Color {
        switch notificationStatus {
        case "Authorized": return GraftColors.success
        case "Denied": return .red
        case "Not Determined": return GraftColors.textSecondary
        default: return GraftColors.textSecondary
        }
    }

    // MARK: - Helpers

    private func loadSettings() {
        reminderEnabled = ReminderService.shared.isEnabled
        reminderHour = ReminderService.shared.reminderHour
        reminderMinute = ReminderService.shared.reminderMinute

        let skills = DatabaseService.shared.getActiveSkills()
        primarySkill = skills.first

        Task {
            let status = await ReminderService.shared.authorizationStatus()
            await MainActor.run {
                switch status {
                case .authorized: notificationStatus = "Authorized"
                case .denied: notificationStatus = "Denied — check Settings app"
                case .notDetermined: notificationStatus = "Not Determined"
                case .provisional: notificationStatus = "Provisional"
                case .ephemeral: notificationStatus = "Ephemeral"
                @unknown default: notificationStatus = "Unknown"
                }
            }
        }
    }

    private func toggleReminder(enabled: Bool) async {
        guard let skill = primarySkill else { return }
        if enabled {
            let granted = await ReminderService.shared.requestAuthorization()
            await MainActor.run {
                if granted {
                    Task {
                        await ReminderService.shared.setEnabled(true, skillName: skill.name, skillEmoji: skill.emoji)
                    }
                    notificationStatus = "Authorized"
                } else {
                    reminderEnabled = false
                    notificationStatus = "Denied — check Settings app"
                }
            }
        } else {
            await ReminderService.shared.setEnabled(false, skillName: skill.name, skillEmoji: skill.emoji)
        }
    }

    private func saveReminderSettings() async {
        guard let skill = primarySkill else { return }
        await ReminderService.shared.setReminderTime(
            hour: reminderHour,
            minute: reminderMinute,
            skillName: skill.name,
            skillEmoji: skill.emoji
        )
    }

    private func applyAISuggestedTime() async {
        guard let skill = primarySkill, let skillId = skill.id else { return }
        await ReminderService.shared.applyAISuggestedTime(
            for: skillId,
            skillName: skill.name,
            skillEmoji: skill.emoji
        )
        reminderHour = ReminderService.shared.reminderHour
        reminderMinute = ReminderService.shared.reminderMinute
    }
}

// MARK: - Reminder Time Picker Sheet

struct ReminderTimePickerSheet: View {
    @Binding var hour: Int
    @Binding var minute: Int
    let skillName: String
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("Set Reminder Time")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(GraftColors.textPrimary)
                        Text("We'll notify you daily to practice \(skillName)")
                            .font(.system(size: 14))
                            .foregroundColor(GraftColors.textSecondary)
                    }
                    .padding(.top, 8)

                    // Time picker
                    DatePicker(
                        "Reminder Time",
                        selection: Binding(
                            get: {
                                var components = DateComponents()
                                components.hour = hour
                                components.minute = minute
                                return Calendar.current.date(from: components) ?? Date()
                            },
                            set: { newDate in
                                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                hour = components.hour ?? 9
                                minute = components.minute ?? 0
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .tint(GraftColors.accent)

                    Spacer()

                    Button {
                        onSave()
                        dismiss()
                    } label: {
                        Text("Set Reminder")
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
            .navigationTitle("Reminder Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(GraftColors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
