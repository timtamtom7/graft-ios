import SwiftUI

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSkill: Skill?
    @State private var skills: [Skill] = []
    @State private var showShareSheet: Bool = false
    @State private var shareItems: [Any] = []
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var isExporting: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        exportOptionsSection
                        if skills.count > 1 {
                            skillSelectorSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Export & Share")
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
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems)
            }
            .onAppear {
                skills = DatabaseService.shared.getActiveSkills()
                selectedSkill = skills.first
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var headerSection: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Practice Data")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Text("Export and share your progress in multiple formats.")
                    .font(.system(size: 14))
                    .foregroundColor(GraftColors.textSecondary)
                    .lineSpacing(4)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Export Options

    private var exportOptionsSection: some View {
        VStack(spacing: 12) {
            // CSV Export
            exportOptionRow(
                icon: "tablecells",
                iconColor: .green,
                title: "Export as CSV",
                subtitle: "Spreadsheet format for all skills"
            ) {
                exportCSV()
            }

            // PDF Practice Log
            exportOptionRow(
                icon: "doc.richtext",
                iconColor: .blue,
                title: "Practice Log (PDF)",
                subtitle: "Formatted report for teachers or yourself"
            ) {
                exportPDF()
            }

            // Practice Report
            exportOptionRow(
                icon: "text.alignleft",
                iconColor: .orange,
                title: "Practice Report",
                subtitle: "Summary with stats, streaks, and feel breakdown"
            ) {
                exportReport()
            }

            // Share as Image
            exportOptionRow(
                icon: "square.and.arrow.up",
                iconColor: .purple,
                title: "Share Progress Image",
                subtitle: "Beautiful card to share on social media"
            ) {
                shareAsImage()
            }

            // Streak Share
            exportOptionRow(
                icon: "flame.fill",
                iconColor: .red,
                title: "Share Streak",
                subtitle: "Show off your current streak"
            ) {
                shareStreak()
            }
        }
    }

    private func exportOptionRow(icon: String, iconColor: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            LiquidGlassCard {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(iconColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(GraftColors.textPrimary)

                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(GraftColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundColor(GraftColors.textSecondary.opacity(0.5))
                }
                .padding(16)
            }
        }
        .disabled(isExporting)
    }

    // MARK: - Skill Selector

    private var skillSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Skill")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(GraftColors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)

            LiquidGlassCard {
                VStack(spacing: 12) {
                    ForEach(skills) { skill in
                        Button {
                            selectedSkill = skill
                        } label: {
                            HStack {
                                Text(skill.emoji)
                                    .font(.system(size: 16))
                                Text(skill.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(GraftColors.textPrimary)
                                Spacer()
                                if selectedSkill?.id == skill.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(GraftColors.accent)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .disabled(isExporting)
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Export Actions

    private func exportCSV() {
        isExporting = true
        Task {
            if let skill = selectedSkill {
                if let url = ExportService.shared.exportCSVForSkill(skill) {
                    shareItems = [url]
                    showShareSheet = true
                } else {
                    await showError(title: "Export Failed", message: "Could not generate CSV file.")
                }
            } else {
                if let url = ExportService.shared.exportCSV(skills: skills) {
                    shareItems = [url]
                    showShareSheet = true
                } else {
                    await showError(title: "Export Failed", message: "Could not generate CSV file.")
                }
            }
            isExporting = false
        }
    }

    private func exportPDF() {
        guard let skill = selectedSkill else {
            alertTitle = "No Skill Selected"
            alertMessage = "Please select a skill first."
            showAlert = true
            return
        }

        isExporting = true
        Task {
            if let url = ExportService.shared.exportPDF(for: skill) {
                shareItems = [url]
                showShareSheet = true
            } else {
                await showError(title: "Export Failed", message: "Could not generate PDF file.")
            }
            isExporting = false
        }
    }

    private func exportReport() {
        guard let skill = selectedSkill else {
            alertTitle = "No Skill Selected"
            alertMessage = "Please select a skill first."
            showAlert = true
            return
        }

        let report = ExportService.shared.generatePracticeReport(for: skill)
        shareItems = [report]
        showShareSheet = true
    }

    private func shareAsImage() {
        isExporting = true
        Task {
            let calendar = Calendar.current
            let now = Date()
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now

            var weeklyTotal = 0
            var streak = 0

            if let skill = selectedSkill, let skillId = skill.id {
                let sessions = DatabaseService.shared.getWeeklySessions(for: skillId, weekStart: weekStart)
                weeklyTotal = sessions.reduce(0) { $0 + $1.totalMinutes }

                // Streak for single skill
                var checkDate = now
                while true {
                    let daySessions = DatabaseService.shared.getSessions(for: skillId, on: checkDate)
                    if daySessions.isEmpty { break }
                    streak += 1
                    guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = prev
                }
            } else {
                // All skills combined
                for skill in skills {
                    guard let skillId = skill.id else { continue }
                    let sessions = DatabaseService.shared.getWeeklySessions(for: skillId, weekStart: weekStart)
                    weeklyTotal += sessions.reduce(0) { $0 + $1.totalMinutes }
                }

                // Overall streak
                var checkDate = now
                while true {
                    var anySession = false
                    for skill in skills {
                        guard let skillId = skill.id else { continue }
                        let daySessions = DatabaseService.shared.getSessions(for: skillId, on: checkDate)
                        if !daySessions.isEmpty { anySession = true; break }
                    }
                    if !anySession { break }
                    streak += 1
                    guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = prev
                }
            }

            if let image = ExportService.shared.generateShareImage(
                skills: skills,
                weeklyMinutes: weeklyTotal,
                streakDays: streak,
                topSkill: selectedSkill
            ) {
                shareItems = [image]
                showShareSheet = true
            } else {
                await showError(title: "Share Failed", message: "Could not generate share image.")
            }
            isExporting = false
        }
    }

    private func shareStreak() {
        let calendar = Calendar.current
        let now = Date()

        var streak = 0
        var skillName = ""
        var skillEmoji = ""

        if let skill = selectedSkill, let skillId = skill.id {
            skillName = skill.name
            skillEmoji = skill.emoji
            var checkDate = now
            while true {
                let daySessions = DatabaseService.shared.getSessions(for: skillId, on: checkDate)
                if daySessions.isEmpty { break }
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            }
        } else {
            skillName = "my skills"
            for skill in skills {
                guard let skillId = skill.id else { continue }
                var checkDate = now
                var currentStreak = 0
                while true {
                    let daySessions = DatabaseService.shared.getSessions(for: skillId, on: checkDate)
                    if daySessions.isEmpty { break }
                    currentStreak += 1
                    guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = prev
                }
                if currentStreak > streak {
                    streak = currentStreak
                    skillName = skill.name
                    skillEmoji = skill.emoji
                }
            }
        }

        let message = "🔥 I'm on a \(streak)-day practice streak for \(skillEmoji) \(skillName)! Keep grinding — tracked with Graft."
        shareItems = [message]
        showShareSheet = true
    }

    private func showError(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
