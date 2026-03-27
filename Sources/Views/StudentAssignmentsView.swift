import SwiftUI

struct StudentAssignmentsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var studentCode: String = ""
    @State private var showJoinError: Bool = false
    @State private var joinErrorMessage: String = ""
    @State private var assignments: [TeacherAssignment] = []
    @State private var connections: [TeacherConnection] = []
    @State private var showLogSession: Bool = false
    @State private var selectedAssignment: TeacherAssignment?
    @State private var showLimitReached: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection

                        if connections.isEmpty {
                            joinTeacherSection
                        } else {
                            assignmentsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Assignments")
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
                        showJoinSheet = true
                    } label: {
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 14))
                            .foregroundColor(GraftColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showJoinSheet) {
                JoinTeacherSheet { code in
                    joinWithCode(code)
                }
            }
            .sheet(isPresented: $showLogSession) {
                if let assignment = selectedAssignment {
                    LogAssignmentSessionSheet(assignment: assignment) {
                        loadData()
                    }
                }
            }
            .alert("Could Not Join", isPresented: $showJoinError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(joinErrorMessage)
            }
            .alert("Assignment Complete!", isPresented: $showAssignmentComplete) {
                Button("OK", role: .cancel) {}
            }
            .onAppear {
                loadData()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    @State private var showJoinSheet: Bool = false
    @State private var showAssignmentComplete: Bool = false

    // MARK: - Header

    private var headerSection: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Practice Assignments")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Text("Your teacher's practice assignments appear here. Log sessions to track your progress.")
                    .font(.system(size: 14))
                    .foregroundColor(GraftColors.textSecondary)
                    .lineSpacing(4)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Join Teacher Section

    private var joinTeacherSection: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 20)

            ZStack {
                Circle()
                    .fill(GraftColors.accent.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "link")
                    .font(.system(size: 36))
                    .foregroundColor(GraftColors.accent)
            }

            Text("No teachers connected")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(GraftColors.textPrimary)

            Text("Ask your teacher for their code and enter it below to join their class.")
                .font(.system(size: 14))
                .foregroundColor(GraftColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            Button {
                showJoinSheet = true
            } label: {
                Text("Enter Teacher Code")
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

    // MARK: - Assignments Section

    private var assignmentsSection: some View {
        VStack(spacing: 12) {
            ForEach(connections) { connection in
                let connectionAssignments = assignments.filter { $0.connectionId == connection.id }
                if !connectionAssignments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(connection.teacherName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(GraftColors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                            .padding(.leading, 4)

                        ForEach(connectionAssignments) { assignment in
                            StudentAssignmentCard(
                                assignment: assignment,
                                onLogSession: {
                                    selectedAssignment = assignment
                                    showLogSession = true
                                },
                                onComplete: {
                                    markComplete(assignment)
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    private func loadData() {
        let studentCode = getStudentCode()
        connections = DatabaseService.shared.getStudentConnections(studentCode: studentCode)
        var allAssignments: [TeacherAssignment] = []
        for connection in connections {
            guard let id = connection.id else { continue }
            allAssignments.append(contentsOf: DatabaseService.shared.getAssignmentsForConnection(id))
        }
        assignments = allAssignments
    }

    private func getStudentCode() -> String {
        // For now, generate a persistent code per device
        let key = "graft_student_code"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let newCode = TeacherConnection.generateCode()
        UserDefaults.standard.set(newCode, forKey: key)
        return newCode
    }

    private func joinWithCode(_ code: String) {
        if let _ = DatabaseService.shared.getTeacherConnection(code: code) {
            loadData()
        } else {
            joinErrorMessage = "No teacher found with that code. Please check and try again."
            showJoinError = true
        }
    }

    private func markComplete(_ assignment: TeacherAssignment) {
        guard let id = assignment.id else { return }
        DatabaseService.shared.markAssignmentCompleted(id: id)
        loadData()
        showAssignmentComplete = true
    }
}

// MARK: - Student Assignment Card

struct StudentAssignmentCard: View {
    let assignment: TeacherAssignment
    let onLogSession: () -> Void
    let onComplete: () -> Void

    @State private var totalMinutes: Int = 0
    @State private var sessionsCount: Int = 0

    var progressPercent: Double {
        guard assignment.targetMinutes > 0 else { return 0 }
        return min(Double(totalMinutes) / Double(assignment.targetMinutes), 1.0)
    }

    var body: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("\(assignment.skillEmoji) \(assignment.title)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(GraftColors.textPrimary)

                    Spacer()

                    if assignment.isCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Done")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(GraftColors.success)
                    }
                }

                if let description = assignment.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(GraftColors.textSecondary)
                        .lineLimit(2)
                }

                HStack {
                    Text("\(formatMinutes(totalMinutes)) / \(assignment.formattedTarget)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(GraftColors.textSecondary)

                    if let deadline = assignment.deadlineText {
                        Text("•")
                            .foregroundColor(GraftColors.textSecondary)
                        Text(deadline)
                            .font(.system(size: 12))
                            .foregroundColor(isOverdue ? GraftColors.accent : GraftColors.textSecondary)
                    }

                    Spacer()

                    Text("\(sessionsCount) sessions logged")
                        .font(.system(size: 11))
                        .foregroundColor(GraftColors.textSecondary)
                }

                ProgressBarGraphic(progress: progressPercent, height: 6)

                HStack(spacing: 10) {
                    Button {
                        onLogSession()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Log Session")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [GraftColors.accent, GraftColors.accentMuted],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(assignment.isCompleted)

                    if progressPercent >= 1.0 && !assignment.isCompleted {
                        Button {
                            HapticFeedback.success()
                            onComplete()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Complete")
                            }
                            .font(.system(size: Theme.FontSize.footnote, weight: .medium))
                            .foregroundColor(GraftColors.success)
                            .padding(.horizontal, Theme.Spacing.xl)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(GraftColors.success.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
                        }
                        .accessibilityLabel("Mark assignment as complete")
                    }
                }
            }
            .padding(16)
        }
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

// MARK: - Log Assignment Session Sheet

struct LogAssignmentSessionSheet: View {
    let assignment: TeacherAssignment
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var durationMinutes: Int = 30
    @State private var feelRating: Int = 3
    @State private var notes: String = ""
    @State private var isSaving: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                VStack(spacing: 28) {
                    // Assignment info
                    VStack(spacing: 4) {
                        Text("\(assignment.skillEmoji) \(assignment.title)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(GraftColors.textPrimary)

                        if let desc = assignment.description {
                            Text(desc)
                                .font(.system(size: 13))
                                .foregroundColor(GraftColors.textSecondary)
                        }
                    }
                    .padding(.top, 8)

                    // Duration
                    VStack(spacing: 12) {
                        Text("How long did you practice?")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(GraftColors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)

                        HStack(spacing: 12) {
                            ForEach([15, 30, 45, 60, 90], id: \.self) { mins in
                                Button {
                                    durationMinutes = mins
                                } label: {
                                    Text("\(mins)m")
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                        .foregroundColor(durationMinutes == mins ? .white : GraftColors.textSecondary)
                                        .frame(width: 50, height: 40)
                                        .background {
                                            if durationMinutes == mins {
                                                LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .leading, endPoint: .trailing)
                                            } else {
                                                Rectangle().fill(GraftColors.surface)
                                            }
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }

                    // Feel rating
                    VStack(spacing: 12) {
                        Text("How did it feel?")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(GraftColors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)

                        HStack(spacing: 16) {
                            ForEach(1...5, id: \.self) { rating in
                                feelDot(rating: rating)
                            }
                        }

                        Text(feelLabel)
                            .font(.system(size: 12))
                            .foregroundColor(GraftColors.textSecondary.opacity(0.7))
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes (optional)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(GraftColors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)

                        TextField("What did you work on?", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                            .font(.system(size: 15))
                            .foregroundColor(GraftColors.textPrimary)
                            .padding(14)
                            .background(GraftColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Spacer()

                    Button {
                        saveSession()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Session")
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
                    .disabled(isSaving)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Log Practice")
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

    private func feelDot(rating: Int) -> some View {
        Button {
            feelRating = rating
        } label: {
            Circle()
                .fill(rating <= feelRating ? GraftColors.accent : GraftColors.surfaceRaised)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .strokeBorder(rating == feelRating ? GraftColors.accent : Color.clear, lineWidth: 2)
                )
                .shadow(color: rating <= feelRating ? GraftColors.accent.opacity(0.4) : .clear, radius: 8)
        }
    }

    private var feelLabel: String {
        switch feelRating {
        case 1: return "Rough start"
        case 2: return "Getting there"
        case 3: return "Solid session"
        case 4: return "Really good"
        case 5: return "Flowing"
        default: return ""
        }
    }

    private func saveSession() {
        guard let assignmentId = assignment.id else { return }
        isSaving = true

        var session = StudentSession(
            assignmentId: assignmentId,
            durationMinutes: durationMinutes,
            feelRating: feelRating,
            notes: notes.isEmpty ? nil : notes,
            practicedAt: Date()
        )

        if DatabaseService.shared.saveStudentSession(&session) {
            onSave()
            dismiss()
        }
        isSaving = false
    }
}

// MARK: - Join Teacher Sheet

struct JoinTeacherSheet: View {
    let onJoin: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var code: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("Enter Teacher Code")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(GraftColors.textPrimary)

                        Text("Ask your teacher for their 6-character code to connect.")
                            .font(.system(size: 14))
                            .foregroundColor(GraftColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 12) {
                        TextField("XXXXXX", text: $code)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(GraftColors.accent)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.plain)
                            .padding(20)
                            .background(GraftColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .autocapitalization(.allCharacters)
                            .onChange(of: code) { _, newValue in
                                code = String(newValue.uppercased().prefix(6))
                            }

                        Text("Code must be 6 characters")
                            .font(.system(size: 12))
                            .foregroundColor(GraftColors.textSecondary)
                    }

                    Spacer()

                    Button {
                        onJoin(code)
                        dismiss()
                    } label: {
                        Text("Connect")
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
                    .disabled(code.count < 6)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Join Teacher")
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
