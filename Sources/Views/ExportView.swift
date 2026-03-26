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
    @State private var showFilePicker: Bool = false
    @State private var showRestorePreview: Bool = false
    @State private var backupPreview: GraftBackupData?
    @State private var backupFileURL: URL?
    @State private var isImporting: Bool = false
    @State private var isRestoring: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        exportOptionsSection
                        backupSection
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
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $showRestorePreview) {
                RestorePreviewSheet(
                    backupData: backupPreview,
                    onRestore: { restoreFromBackup() },
                    isRestoring: isRestoring
                )
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

    // MARK: - Backup Section

    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Backup & Restore")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(GraftColors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)

            VStack(spacing: 10) {
                // Backup
                exportOptionRow(
                    icon: "arrow.down.doc",
                    iconColor: .cyan,
                    title: "Backup All Data",
                    subtitle: "JSON file with all skills, sessions, and goals"
                ) {
                    exportBackup()
                }

                // Restore
                exportOptionRow(
                    icon: "arrow.up.doc",
                    iconColor: .yellow,
                    title: "Restore from Backup",
                    subtitle: "Import data from a Graft backup file"
                ) {
                    showFilePicker = true
                }
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

    // MARK: - Backup & Restore

    private func exportBackup() {
        isExporting = true
        Task {
            if let url = ExportService.shared.exportJSON() {
                shareItems = [url]
                showShareSheet = true
            } else {
                await showError(title: "Backup Failed", message: "Could not generate backup file. Please try again.")
            }
            isExporting = false
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                alertTitle = "Access Denied"
                alertMessage = "Could not access the selected file."
                showAlert = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            if let preview = ExportService.shared.previewBackup(at: url) {
                backupPreview = preview
                backupFileURL = url
                showRestorePreview = true
            } else {
                alertTitle = "Invalid Backup File"
                alertMessage = "The selected file is not a valid Graft backup."
                showAlert = true
            }

        case .failure(let error):
            alertTitle = "Import Failed"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func restoreFromBackup() {
        guard let url = backupFileURL else { return }
        isRestoring = true

        Task {
            if let count = await ExportService.shared.importJSON(from: url) {
                await MainActor.run {
                    isRestoring = false
                    showRestorePreview = false
                    alertTitle = "Restore Complete"
                    alertMessage = "Successfully imported \(count) items from backup."
                    showAlert = true
                    // Refresh skills list
                    skills = DatabaseService.shared.getActiveSkills()
                    selectedSkill = skills.first
                }
            } else {
                await MainActor.run {
                    isRestoring = false
                    alertTitle = "Restore Failed"
                    alertMessage = "Could not restore from the backup file. The data may be corrupted."
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Restore Preview Sheet

struct RestorePreviewSheet: View {
    let backupData: GraftBackupData?
    let onRestore: () -> Void
    let isRestoring: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                if let data = backupData {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(GraftColors.accent.opacity(0.15))
                                        .frame(width: 80, height: 80)
                                    Image(systemName: "arrow.up.doc.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(GraftColors.accent)
                                }

                                Text("Backup Details")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(GraftColors.textPrimary)

                                Text("Exported \(formattedDate(data.exportedAt))")
                                    .font(.system(size: 13))
                                    .foregroundColor(GraftColors.textSecondary)
                            }
                            .padding(.top, 20)

                            // Stats
                            LiquidGlassCard {
                                VStack(spacing: 16) {
                                    previewStatRow(icon: "book.fill", label: "Skills", value: "\(data.skills.count)")
                                    Divider().background(GraftColors.textSecondary.opacity(0.2))
                                    previewStatRow(icon: "clock.fill", label: "Sessions", value: "\(data.sessions.count)")
                                    Divider().background(GraftColors.textSecondary.opacity(0.2))
                                    previewStatRow(icon: "target", label: "Goals", value: "\(data.goals.count)")
                                    Divider().background(GraftColors.textSecondary.opacity(0.2))
                                    previewStatRow(icon: "calendar", label: "Planned Sessions", value: "\(data.plans.count)")
                                }
                                .padding(.vertical, 8)
                            }

                            // Skills breakdown
                            if !data.skills.isEmpty {
                                LiquidGlassCard {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Included Skills")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(GraftColors.textSecondary)
                                            .textCase(.uppercase)
                                            .tracking(1.2)

                                        ForEach(data.skills) { skill in
                                            HStack(spacing: 10) {
                                                Text(skill.emoji)
                                                    .font(.system(size: 16))
                                                Text(skill.name)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(GraftColors.textPrimary)
                                                Spacer()
                                                let count = data.sessions.filter { $0.skillId == skill.id }.count
                                                Text("\(count) sessions")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(GraftColors.textSecondary)
                                            }
                                        }
                                    }
                                    .padding(16)
                                }
                            }

                            // Warning
                            LiquidGlassCard {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Existing data with the same IDs will be merged. Duplicate skills will be created.")
                                        .font(.system(size: 13))
                                        .foregroundColor(GraftColors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(16)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                } else {
                    VStack(spacing: 16) {
                        ProgressView().tint(GraftColors.accent)
                        Text("Loading backup preview...")
                            .font(.system(size: 14))
                            .foregroundColor(GraftColors.textSecondary)
                    }
                }
            }
            .navigationTitle("Restore Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(GraftColors.textSecondary)
                        .disabled(isRestoring)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isRestoring {
                        ProgressView()
                            .tint(GraftColors.accent)
                    } else {
                        Button("Restore") { onRestore() }
                            .foregroundColor(GraftColors.accent)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func previewStatRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(GraftColors.accent)
                .frame(width: 24)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(GraftColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(GraftColors.textPrimary)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
