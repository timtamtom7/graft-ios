import SwiftUI

/// A searchable, browsable history of all practice sessions across skills
struct SessionHistoryView: View {
    let skills: [Skill]

    @Environment(\.dismiss) private var dismiss
    @State private var allSessions: [(session: Session, skill: Skill)] = []
    @State private var searchText: String = ""
    @State private var isLoading: Bool = true
    @State private var selectedSession: (session: Session, skill: Skill)?
    @State private var showSessionDetail: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var sessionToDelete: (session: Session, skill: Skill)?
    @State private var showEditSheet: Bool = false
    @State private var sessionToEdit: (session: Session, skill: Skill)?

    private var filteredSessions: [(session: Session, skill: Skill)] {
        guard !searchText.isEmpty else { return allSessions }
        let query = searchText.lowercased()
        return allSessions.filter { item in
            item.skill.name.lowercased().contains(query) ||
            (item.session.notes?.lowercased().contains(query) ?? false) ||
            String(item.session.durationMinutes).contains(query) ||
            String(item.session.feelRating).contains(query)
        }
    }

    private var groupedSessions: [(date: Date, sessions: [(session: Session, skill: Skill)])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredSessions) { item in
            calendar.startOfDay(for: item.session.practicedAt)
        }
        return grouped.sorted { $0.key > $1.key }.map { ($0.key, $0.value.sorted { $0.session.practicedAt > $1.session.practicedAt }) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if allSessions.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("Session History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(GraftColors.accent)
                }
            }
            .searchable(text: $searchText, prompt: "Search sessions, notes, skills...")
            .sheet(isPresented: $showSessionDetail) {
                if let item = selectedSession {
                    SessionDetailSheet(session: item.session, skill: item.skill) {
                        loadSessions()
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if let item = sessionToEdit {
                    EditSessionSheet(session: item.session, skill: item.skill) {
                        loadSessions()
                    }
                }
            }
            .alert("Delete Session?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let item = sessionToDelete {
                        deleteSession(item)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove this practice session. This cannot be undone.")
            }
            .onAppear { loadSessions() }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(GraftColors.accent)
            Text("Loading sessions...")
                .font(.system(size: 14))
                .foregroundColor(GraftColors.textSecondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(GraftColors.accent.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 40))
                    .foregroundColor(GraftColors.accent)
            }

            VStack(spacing: 8) {
                Text("No sessions yet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(GraftColors.textPrimary)

                Text("Your practice history will appear here once you log your first session.")
                    .font(.system(size: 14))
                    .foregroundColor(GraftColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                if filteredSessions.isEmpty && !searchText.isEmpty {
                    noResultsView
                } else {
                    ForEach(groupedSessions, id: \.date) { group in
                        Section {
                            ForEach(group.sessions, id: \.session.id) { item in
                                sessionRow(item: item)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("\(item.skill.emoji) \(item.skill.name), \(item.session.formattedDuration), feel rating \(item.session.feelRating) out of 5, practiced \(formattedDate(item.session.practicedAt))")
                                    .accessibilityHint("Double tap to view details")
                            }
                        } header: {
                            sectionHeader(for: group.date)
                        }
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(GraftColors.textSecondary.opacity(0.5))

            Text("No results for \"\(searchText)\"")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(GraftColors.textSecondary)

            Text("Try searching for a different skill, note, or duration.")
                .font(.system(size: 13))
                .foregroundColor(GraftColors.textSecondary.opacity(0.7))
            Spacer()
        }
        .padding(.top, 40)
    }

    private func sectionHeader(for date: Date) -> some View {
        HStack {
            Text(sectionDateLabel(for: date))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(GraftColors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)

            Spacer()

            let totalMinutes = groupedSessions.first { Calendar.current.isDate($0.date, inSameDayAs: date) }?.sessions.reduce(0) { $0 + $1.session.durationMinutes } ?? 0
            if totalMinutes > 0 {
                Text(formatMinutes(totalMinutes))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(GraftColors.accent.opacity(0.8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(GraftColors.background)
    }

    private func sessionRow(item: (session: Session, skill: Skill)) -> some View {
        Button {
            selectedSession = item
            showSessionDetail = true
        } label: {
            HStack(spacing: 14) {
                // Skill emoji badge
                Text(item.skill.emoji)
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(GraftColors.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.skill.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(GraftColors.textPrimary)

                    if let notes = item.session.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 12))
                            .foregroundColor(GraftColors.textSecondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        Text(timeString(for: item.session.practicedAt))
                            .font(.system(size: 11))
                            .foregroundColor(GraftColors.textSecondary.opacity(0.6))

                        if item.session.isTimerBased {
                            HStack(spacing: 2) {
                                Image(systemName: "timer")
                                    .font(.system(size: 9))
                                Text("Timer")
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(GraftColors.accent.opacity(0.7))
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(item.session.formattedDuration)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(GraftColors.textPrimary)

                    feelDots(rating: item.session.feelRating)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(GraftColors.background)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                HapticFeedback.light()
                sessionToEdit = item
                showEditSheet = true
            } label: {
                Label("Edit Session", systemImage: "pencil")
            }

            Button(role: .destructive) {
                HapticFeedback.warning()
                sessionToDelete = item
                showDeleteConfirmation = true
            } label: {
                Label("Delete Session", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                HapticFeedback.warning()
                sessionToDelete = item
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                HapticFeedback.light()
                sessionToEdit = item
                showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(GraftColors.accent)
        }
    }

    private func feelDots(rating: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { r in
                Circle()
                    .fill(r <= rating ? GraftColors.accent : GraftColors.surfaceRaised)
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Helpers

    private func loadSessions() {
        isLoading = true
        DispatchQueue.main.async {
            var sessions: [(Session, Skill)] = []
            for skill in skills {
                guard let skillId = skill.id else { continue }
                let skillSessions = DatabaseService.shared.getAllSessions(for: skillId)
                for session in skillSessions {
                    sessions.append((session, skill))
                }
            }
            // Sort by most recent first
            sessions.sort { $0.0.practicedAt > $1.0.practicedAt }
            self.allSessions = sessions
            self.isLoading = false
        }
    }

    private func deleteSession(_ item: (session: Session, skill: Skill)) {
        guard let sessionId = item.session.id else { return }
        // We need a delete method on DatabaseService - we'll add it inline for now
        Task {
            await deleteSessionFromDB(sessionId: sessionId)
            loadSessions()
            WidgetDataManager.shared.refreshWidgetData()
        }
    }

    private func sectionDateLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }

    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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

// MARK: - Database Helper (delete session)

@MainActor
private func deleteSessionFromDB(sessionId: Int64) {
    _ = DatabaseService.shared.deleteSession(id: sessionId)
}

// MARK: - Session Detail Sheet

struct SessionDetailSheet: View {
    let session: Session
    let skill: Skill
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Text(skill.emoji)
                                .font(.system(size: 48))
                                .frame(width: 80, height: 80)
                                .background(GraftColors.surfaceRaised)
                                .clipShape(Circle())

                            Text(skill.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(GraftColors.textPrimary)

                            Text(formattedDate)
                                .font(.system(size: 13))
                                .foregroundColor(GraftColors.textSecondary)
                        }
                        .padding(.top, 20)

                        // Stats
                        LiquidGlassCard {
                            HStack(spacing: 0) {
                                statItem(value: session.formattedDuration, label: "Duration", icon: "clock")
                                Divider().frame(height: 40).background(GraftColors.textSecondary.opacity(0.2))
                                statItem(value: feelLabel, label: "Feel", icon: "star")
                                if session.isTimerBased {
                                    Divider().frame(height: 40).background(GraftColors.textSecondary.opacity(0.2))
                                    statItem(value: "Timer", label: "Method", icon: "timer")
                                }
                            }
                            .padding(.vertical, 8)
                        }

                        // Feel breakdown
                        LiquidGlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Feel Rating")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(GraftColors.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(1.2)

                                HStack(spacing: 8) {
                                    ForEach(1...5, id: \.self) { rating in
                                        Circle()
                                            .fill(rating <= session.feelRating ? GraftColors.accent : GraftColors.surfaceRaised)
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Text("\(rating)")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(rating <= session.feelRating ? .white : GraftColors.textSecondary)
                                            )
                                    }
                                    Spacer()
                                }

                                Text(feelLongLabel)
                                    .font(.system(size: 14))
                                    .foregroundColor(GraftColors.accent)
                            }
                            .padding(16)
                        }

                        // Notes
                        if let notes = session.notes, !notes.isEmpty {
                            LiquidGlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Notes")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(GraftColors.textSecondary)
                                        .textCase(.uppercase)
                                        .tracking(1.2)

                                    Text(notes)
                                        .font(.system(size: 15))
                                        .foregroundColor(GraftColors.textPrimary)
                                        .lineSpacing(4)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(16)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(GraftColors.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var feelLabel: String {
        switch session.feelRating {
        case 1: return "⭐"
        case 2: return "⭐⭐"
        case 3: return "⭐⭐⭐"
        case 4: return "⭐⭐⭐⭐"
        case 5: return "⭐⭐⭐⭐⭐"
        default: return "—"
        }
    }

    private var feelLongLabel: String {
        switch session.feelRating {
        case 1: return "Rough start"
        case 2: return "Getting there"
        case 3: return "Solid session"
        case 4: return "Really good"
        case 5: return "Flowing perfectly"
        default: return ""
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: session.practicedAt)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(GraftColors.accent)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(GraftColors.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(GraftColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Edit Session Sheet

struct EditSessionSheet: View {
    let session: Session
    let skill: Skill
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var hours: Int
    @State private var minutes: Int
    @State private var feelRating: Int
    @State private var notes: String
    @State private var isSaving: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    init(session: Session, skill: Skill, onSave: @escaping () -> Void) {
        self.session = session
        self.skill = skill
        self.onSave = onSave
        _hours = State(initialValue: session.durationMinutes / 60)
        _minutes = State(initialValue: session.durationMinutes % 60)
        _feelRating = State(initialValue: session.feelRating)
        _notes = State(initialValue: session.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Skill header
                        HStack(spacing: 12) {
                            Text(skill.emoji)
                                .font(.system(size: 24))
                            Text(skill.name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(GraftColors.textPrimary)
                        }
                        .padding(.top, 8)

                        durationSection
                        feelSection
                        notesSection
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(GraftColors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveSession() }
                        .fontWeight(.semibold)
                        .foregroundColor(isSaving ? GraftColors.textSecondary : GraftColors.accent)
                        .disabled(totalMinutes == 0 || isSaving)
                }
            }
            .alert("Could Not Update", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var durationSection: some View {
        VStack(spacing: 16) {
            Text("Duration")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(GraftColors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)

            HStack(spacing: 0) {
                Picker("Hours", selection: $hours) {
                    ForEach(0..<9) { h in Text("\(h)h").tag(h) }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
                .clipped()

                Picker("Minutes", selection: $minutes) {
                    ForEach(0..<60) { m in
                        if m % 5 == 0 { Text("\(m)m").tag(m) }
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
                .clipped()
            }
            .frame(height: 120)

            Text(formattedDuration)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(GraftColors.textPrimary)
        }
    }

    private var feelSection: some View {
        VStack(spacing: 16) {
            Text("How did it feel?")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(GraftColors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)

            HStack(spacing: 20) {
                ForEach(1...5, id: \.self) { rating in
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
            }

            Text(feelLabel)
                .font(.system(size: 12))
                .foregroundColor(GraftColors.textSecondary.opacity(0.7))
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notes")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(GraftColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)
                Spacer()
                Text("\(notes.count)/140")
                    .font(.system(size: 11))
                    .foregroundColor(GraftColors.textSecondary.opacity(0.6))
            }

            TextField("What did you work on? (optional)", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundColor(GraftColors.textPrimary)
                .padding(14)
                .background(GraftColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: notes) { _, newValue in
                    if newValue.count > 140 {
                        notes = String(newValue.prefix(140))
                    }
                }
        }
    }

    private var totalMinutes: Int { hours * 60 + minutes }

    private var formattedDuration: String {
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
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
        guard totalMinutes > 0, let sessionId = session.id else { return }
        isSaving = true

        var updatedSession = session
        updatedSession.durationMinutes = totalMinutes
        updatedSession.feelRating = feelRating
        updatedSession.notes = notes.isEmpty ? nil : notes

        let success = DatabaseService.shared.saveSession(&updatedSession)
        if success {
            WidgetDataManager.shared.refreshWidgetData()
            onSave()
            dismiss()
        } else {
            isSaving = false
            errorMessage = "Could not update the session. Please try again."
            showError = true
        }
    }
}
