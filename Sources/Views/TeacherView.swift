import SwiftUI

struct TeacherView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var connections: [TeacherConnection] = []
    @State private var selectedConnection: TeacherConnection?
    @State private var showCreateAssignment: Bool = false
    @State private var showCreateConnection: Bool = false
    @State private var showCopiedAlert: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection

                        if connections.isEmpty {
                            emptyState
                        } else {
                            connectionsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Teacher")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(GraftColors.textSecondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateConnection = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14))
                            .foregroundColor(GraftColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showCreateConnection) {
                CreateConnectionSheet { connection in
                    connections.append(connection)
                    selectedConnection = connection
                }
            }
            .sheet(isPresented: $showCreateAssignment) {
                if let connection = selectedConnection {
                    CreateAssignmentSheet(connection: connection) { assignment in
                        // Assignment created
                    }
                }
            }
            .alert("Code Copied!", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) {}
            }
            .onAppear {
                loadConnections()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var headerSection: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Students")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Text("Create practice assignments for your students and track their progress.")
                    .font(.system(size: 14))
                    .foregroundColor(GraftColors.textSecondary)
                    .lineSpacing(4)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 40)

            ZStack {
                Circle()
                    .fill(GraftColors.accent.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 36))
                    .foregroundColor(GraftColors.accent)
            }

            Text("No students yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(GraftColors.textPrimary)

            Text("Create a connection code and share it with your student to start tracking their practice.")
                .font(.system(size: 14))
                .foregroundColor(GraftColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            Button {
                showCreateConnection = true
            } label: {
                Text("Add Student")
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

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Connections Section

    private var connectionsSection: some View {
        VStack(spacing: 12) {
            ForEach(connections) { connection in
                ConnectionCard(
                    connection: connection,
                    isSelected: selectedConnection?.id == connection.id,
                    onSelect: {
                        selectedConnection = connection
                        showCreateAssignment = true
                    },
                    onCopyCode: {
                        copyStudentCode(connection.studentCode)
                    }
                )
            }
        }
    }

    private func loadConnections() {
        connections = DatabaseService.shared.getTeacherConnections()
    }

    private func copyStudentCode(_ code: String) {
        UIPasteboard.general.string = code
        showCopiedAlert = true
    }
}

// MARK: - Connection Card

struct ConnectionCard: View {
    let connection: TeacherConnection
    let isSelected: Bool
    let onSelect: () -> Void
    let onCopyCode: () -> Void

    @State private var showAssignments: Bool = false
    @State private var assignments: [TeacherAssignment] = []
    @State private var progress: (totalMinutes: Int, sessionsCount: Int) = (0, 0)

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { showAssignments.toggle() } }) {
                LiquidGlassCard {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(GraftColors.accent.opacity(0.2))
                                .frame(width: 48, height: 48)
                            Text(String(connection.studentName.prefix(1)))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(GraftColors.accent)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(connection.studentName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(GraftColors.textPrimary)

                            Text("\(assignments.count) assignments")
                                .font(.system(size: 12))
                                .foregroundColor(GraftColors.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(formatMinutes(progress.totalMinutes))
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(GraftColors.accent)
                            Text("\(progress.sessionsCount) sessions")
                                .font(.system(size: 11))
                                .foregroundColor(GraftColors.textSecondary)
                        }

                        Image(systemName: showAssignments ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(GraftColors.textSecondary)
                    }
                    .padding(16)
                }
            }
            .buttonStyle(.plain)

            if showAssignments {
                VStack(spacing: 8) {
                    // Student code row
                    HStack {
                        Text("Student code:")
                            .font(.system(size: 11))
                            .foregroundColor(GraftColors.textSecondary)
                        Text(connection.studentCode)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(GraftColors.accent)
                        Spacer()
                        Button {
                            onCopyCode()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 11))
                                .foregroundColor(GraftColors.accent)
                        }
                    }
                    .padding(.horizontal, 16)

                    ForEach(assignments) { assignment in
                        AssignmentRow(assignment: assignment)
                    }

                    Button {
                        onSelect()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Assignment")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(GraftColors.accent)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.bottom, 12)
                .background(GraftColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 4)
            }
        }
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        guard let id = connection.id else { return }
        assignments = DatabaseService.shared.getAssignmentsForConnection(id)
        progress = DatabaseService.shared.getStudentProgressForConnection(id)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(mins)m"
    }
}

// MARK: - Assignment Row

struct AssignmentRow: View {
    let assignment: TeacherAssignment

    @State private var totalMinutes: Int = 0
    @State private var sessionsCount: Int = 0

    var progressPercent: Double {
        guard assignment.targetMinutes > 0 else { return 0 }
        return min(Double(totalMinutes) / Double(assignment.targetMinutes), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(assignment.skillEmoji) \(assignment.title)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GraftColors.textPrimary)
                Spacer()
                if assignment.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(GraftColors.success)
                }
            }

            HStack {
                Text("\(formatMinutes(totalMinutes)) / \(assignment.formattedTarget)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(GraftColors.textSecondary)

                if let deadline = assignment.deadlineText {
                    Text("•")
                        .foregroundColor(GraftColors.textSecondary)
                    Text(deadline)
                        .font(.system(size: 11))
                        .foregroundColor(isOverdue ? GraftColors.accent : GraftColors.textSecondary)
                }

                Spacer()

                Text("\(sessionsCount) sessions")
                    .font(.system(size: 11))
                    .foregroundColor(GraftColors.textSecondary)
            }

            ProgressBarGraphic(progress: progressPercent, height: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(GraftColors.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 8)
        .onAppear {
            loadData()
        }
    }

    private var isOverdue: Bool {
        guard let deadline = assignment.deadline else { return false }
        return deadline < Date() && !assignment.isCompleted
    }

    private func loadData() {
        guard let id = assignment.id else { return }
        totalMinutes = DatabaseService.shared.getTotalMinutesForAssignment(id)
        sessionsCount = DatabaseService.shared.getStudentSessions(for: id).count
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(mins)m"
    }
}

// MARK: - Create Connection Sheet

struct CreateConnectionSheet: View {
    let onSave: (TeacherConnection) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var studentName: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("Add Student")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(GraftColors.textPrimary)

                        Text("Enter your student's name to create a connection code they can use.")
                            .font(.system(size: 14))
                            .foregroundColor(GraftColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Student's Name")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(GraftColors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)

                        TextField("e.g. Alex", text: $studentName)
                            .font(.system(size: 16))
                            .foregroundColor(GraftColors.textPrimary)
                            .padding(14)
                            .background(GraftColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Spacer()

                    Button {
                        saveConnection()
                    } label: {
                        Text("Create Connection")
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
                    .disabled(studentName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Add Student")
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

    private func saveConnection() {
        let teacherCode = TeacherConnection.generateCode()
        let studentCode = TeacherConnection.generateCode()
        let trimmedName = studentName.trimmingCharacters(in: .whitespaces)

        var connection = TeacherConnection(
            teacherCode: teacherCode,
            studentCode: studentCode,
            teacherName: "Teacher",
            studentName: trimmedName,
            createdAt: Date()
        )

        if DatabaseService.shared.saveTeacherConnection(&connection) {
            onSave(connection)
            dismiss()
        }
    }
}

// MARK: - Create Assignment Sheet

struct CreateAssignmentSheet: View {
    let connection: TeacherConnection
    let onSave: (TeacherAssignment) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var skillName: String = ""
    @State private var skillEmoji: String = "🎯"
    @State private var targetMinutes: Int = 60
    @State private var targetSessions: Int = 3
    @State private var hasDeadline: Bool = false
    @State private var deadline: Date = Date().addingTimeInterval(7 * 24 * 3600)

    private let skillOptions = ["🎸 Guitar", "🎹 Piano", "💻 Coding", "📖 Reading", "🏀 Basketball", "🎨 Art", "🗣️ Language", "🎻 Violin", "🥁 Drums", "🎤 Singing"]

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Student info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("For")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(GraftColors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1.2)

                            HStack {
                                Text(connection.studentName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(GraftColors.accent)
                                Spacer()
                            }
                        }

                        // Title
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Assignment Title")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(GraftColors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1.2)

                            TextField("e.g. Practice scales", text: $title)
                                .font(.system(size: 16))
                                .foregroundColor(GraftColors.textPrimary)
                                .padding(14)
                                .background(GraftColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Skill
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Skill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(GraftColors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1.2)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(skillOptions, id: \.self) { option in
                                        let emoji = String(option.prefix(2))
                                        let name = String(option.dropFirst(3))
                                        Button {
                                            skillEmoji = emoji
                                            skillName = name
                                        } label: {
                                            HStack(spacing: 4) {
                                                Text(emoji)
                                                    .font(.system(size: 14))
                                                Text(name)
                                                    .font(.system(size: 12, weight: .medium))
                                            }
                                            .foregroundColor(skillEmoji == emoji ? .white : GraftColors.textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background {
                                                if skillEmoji == emoji {
                                                    LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .leading, endPoint: .trailing)
                                                } else {
                                                    Rectangle().fill(GraftColors.surface)
                                                }
                                            }
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }

                        // Target minutes
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Target Practice Time")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(GraftColors.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(1.2)
                                Spacer()
                                Text(formatMinutes(targetMinutes))
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundColor(GraftColors.accent)
                            }

                            Slider(value: Binding(
                                get: { Double(targetMinutes) },
                                set: { targetMinutes = Int($0) }
                            ), in: 15...300, step: 15)
                            .tint(GraftColors.accent)
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes (optional)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(GraftColors.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1.2)

                            TextField("What should they focus on?", text: $description, axis: .vertical)
                                .lineLimit(2...4)
                                .font(.system(size: 15))
                                .foregroundColor(GraftColors.textPrimary)
                                .padding(14)
                                .background(GraftColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Deadline
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $hasDeadline) {
                                Text("Set Deadline")
                                    .font(.system(size: 14))
                                    .foregroundColor(GraftColors.textPrimary)
                            }
                            .tint(GraftColors.accent)

                            if hasDeadline {
                                DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .tint(GraftColors.accent)
                                    .foregroundColor(GraftColors.textSecondary)
                            }
                        }

                        Spacer(minLength: 20)

                        Button {
                            saveAssignment()
                        } label: {
                            Text("Create Assignment")
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
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Assignment")
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

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        }
        return "\(mins)m"
    }

    private func saveAssignment() {
        guard let connectionId = connection.id else { return }

        var assignment = TeacherAssignment(
            connectionId: connectionId,
            skillName: skillName.isEmpty ? "Practice" : skillName,
            skillEmoji: skillEmoji,
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.isEmpty ? nil : description,
            targetMinutes: targetMinutes,
            targetSessions: targetSessions,
            deadline: hasDeadline ? deadline : nil,
            isCompleted: false,
            createdAt: Date()
        )

        if DatabaseService.shared.saveTeacherAssignment(&assignment) {
            onSave(assignment)
            dismiss()
        }
    }
}
