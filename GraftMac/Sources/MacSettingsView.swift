import SwiftUI

struct MacSettingsView: View {
    @ObservedObject var viewModel: MacMainViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showAddSkill = false
    @State private var newSkillName = ""
    @State private var newSkillEmoji = "🎯"
    @State private var showExportSheet = false
    @State private var exportedJSON: String = ""
    @State private var exportMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Settings")
                    .font(.headline)
                    .foregroundColor(GraftColors.textPrimary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(GraftColors.textSecondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(GraftColors.surface)

            Divider().background(GraftColors.surfaceRaised)

            ScrollView {
                VStack(spacing: 24) {
                    skillsSection
                    dataSection
                    aboutSection
                }
                .padding(24)
            }

            Spacer()
        }
        .frame(width: 440, height: 500)
        .background(GraftColors.background)
        .sheet(isPresented: $showAddSkill) {
            addSkillSheet
        }
        .sheet(isPresented: $showExportSheet) {
            exportSheet
        }
    }

    // MARK: - Skills Section

    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Skills")

            VStack(spacing: 0) {
                ForEach(viewModel.skills) { skill in
                    HStack {
                        Text(skill.emoji)
                            .font(.title3)
                        Text(skill.name)
                            .foregroundColor(GraftColors.textPrimary)
                        Spacer()
                        if skill.id == viewModel.activeSkill?.id {
                            Text("Active")
                                .font(.caption)
                                .foregroundColor(GraftColors.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(GraftColors.accent.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.activeSkill = skill
                        viewModel.refresh()
                    }

                    if skill.id != viewModel.skills.last?.id {
                        Divider().background(GraftColors.surfaceRaised)
                    }
                }
            }
            .background(GraftColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button {
                showAddSkill = true
            } label: {
                Label("Add New Skill", systemImage: "plus")
                    .font(.subheadline)
                    .foregroundColor(GraftColors.accent)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Data")

            VStack(spacing: 0) {
                Button {
                    exportData()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline)
                            .foregroundColor(GraftColors.textSecondary)
                            .frame(width: 24)
                        Text("Export All Data (JSON)")
                            .font(.subheadline)
                            .foregroundColor(GraftColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(GraftColors.textSecondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                }
                .buttonStyle(.plain)
            }
            .background(GraftColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if let message = exportMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(GraftColors.accent)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("About")

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Version")
                        .font(.subheadline)
                        .foregroundColor(GraftColors.textSecondary)
                    Spacer()
                    Text("1.0.0")
                        .font(.subheadline)
                        .foregroundColor(GraftColors.textPrimary)
                }
                HStack {
                    Text("Built with")
                        .font(.subheadline)
                        .foregroundColor(GraftColors.textSecondary)
                    Spacer()
                    Text("SwiftUI + SQLite")
                        .font(.subheadline)
                        .foregroundColor(GraftColors.textPrimary)
                }
            }
            .padding(14)
            .background(GraftColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Add Skill Sheet

    private var addSkillSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("New Skill")
                    .font(.headline)
                    .foregroundColor(GraftColors.textPrimary)
                Spacer()
                Button {
                    showAddSkill = false
                    newSkillName = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(GraftColors.textSecondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(GraftColors.surface)

            Divider().background(GraftColors.surfaceRaised)

            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Emoji")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(GraftColors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.2)

                    TextField("🎯", text: $newSkillEmoji)
                        .textFieldStyle(.plain)
                        .font(.title)
                        .frame(width: 60, height: 44)
                        .multilineTextAlignment(.center)
                        .background(GraftColors.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Skill Name")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(GraftColors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.2)

                    TextField("e.g. Piano", text: $newSkillName)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundColor(GraftColors.textPrimary)
                        .padding(12)
                        .background(GraftColors.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    addSkill()
                } label: {
                    Text("Add Skill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }
                .buttonStyle(.plain)
                .background(newSkillName.isEmpty ? GraftColors.surfaceRaised : GraftColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(newSkillName.isEmpty)
            }
            .padding(24)
        }
        .frame(width: 360, height: 320)
        .background(GraftColors.background)
    }

    // MARK: - Export Sheet

    private var exportSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Exported Data")
                    .font(.headline)
                    .foregroundColor(GraftColors.textPrimary)
                Spacer()
                Button {
                    showExportSheet = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(GraftColors.textSecondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(GraftColors.surface)

            Divider().background(GraftColors.surfaceRaised)

            ScrollView {
                Text(exportedJSON)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(GraftColors.textSecondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(GraftColors.surface)

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(exportedJSON, forType: .string)
                exportMessage = "Copied to clipboard!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    exportMessage = nil
                }
            } label: {
                Text("Copy to Clipboard")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
            }
            .buttonStyle(.plain)
            .background(GraftColors.accent)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(16)
        }
        .frame(width: 440, height: 420)
        .background(GraftColors.background)
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(GraftColors.textSecondary)
            .textCase(.uppercase)
            .tracking(1.2)
    }

    private func addSkill() {
        var skill = Skill(name: newSkillName, emoji: newSkillEmoji)
        let success = DatabaseService.shared.saveSkill(&skill)
        if success {
            viewModel.loadSkills()
            newSkillName = ""
            showAddSkill = false
        }
    }

    private func exportData() {
        let skills = DatabaseService.shared.getAllSkills()
        var allSessions: [Session] = []
        for skill in skills {
            if let id = skill.id {
                let sessions = DatabaseService.shared.getAllSessions(for: id)
                allSessions.append(contentsOf: sessions)
            }
        }

        let backup = MacExportData(
            version: 1,
            exportedAt: Date(),
            skills: skills,
            sessions: allSessions
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let jsonData = try? encoder.encode(backup) {
            exportedJSON = String(data: jsonData, encoding: .utf8) ?? "[]"
            showExportSheet = true
        } else {
            exportMessage = "Failed to encode export data"
        }
    }
}

// MARK: - Export Data Model

struct MacExportData: Codable {
    let version: Int
    let exportedAt: Date
    var skills: [MacExportSkill]
    var sessions: [MacExportSession]

    init(version: Int, exportedAt: Date, skills: [Skill], sessions: [Session]) {
        self.version = version
        self.exportedAt = exportedAt
        self.skills = skills.map { MacExportSkill(skill: $0) }
        self.sessions = sessions.map { MacExportSession(session: $0) }
    }
}

struct MacExportSkill: Codable {
    let id: Int64?
    let name: String
    let emoji: String
    let isActive: Bool
    let createdAt: Date

    init(skill: Skill) {
        self.id = skill.id
        self.name = skill.name
        self.emoji = skill.emoji
        self.isActive = skill.isActive
        self.createdAt = skill.createdAt
    }
}

struct MacExportSession: Codable {
    let id: Int64?
    let skillId: Int64
    let durationMinutes: Int
    let feelRating: Int
    let notes: String?
    let practicedAt: Date
    let isTimerBased: Bool

    init(session: Session) {
        self.id = session.id
        self.skillId = session.skillId
        self.durationMinutes = session.durationMinutes
        self.feelRating = session.feelRating
        self.notes = session.notes
        self.practicedAt = session.practicedAt
        self.isTimerBased = session.isTimerBased
    }
}
