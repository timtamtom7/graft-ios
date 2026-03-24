import SwiftUI

struct PracticeTimerView: View {
    let skills: [Skill]
    var onSave: (() -> Void)? = nil

    @State private var selectedSkill: Skill?
    @State private var selectedDuration: Int = 25
    @State private var isRunning: Bool = false
    @State private var elapsedSeconds: Int = 0
    @State private var runningTimer: Timer?
    @State private var showFeelRating: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSessionLog: Bool = false
    @State private var feelRating: Int = 3

    @Environment(\.dismiss) private var dismiss

    private let presets: [Int] = [15, 25, 45, 60, 90]

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                VStack(spacing: 32) {
                    if skills.count > 1 {
                        skillSelector
                    }

                    Spacer()

                    timerDisplay

                    if !isRunning && !showFeelRating {
                        presetSelector
                    }

                    Spacer()

                    if !showFeelRating {
                        actionButtons
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .navigationTitle("Practice Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        stopTimer()
                        dismiss()
                    }
                    .foregroundColor(GraftColors.textSecondary)
                }
            }
            .sheet(isPresented: $showSessionLog) {
                LogSessionSheet(
                    skillId: selectedSkill?.id ?? 0,
                    onSave: {
                        dismiss()
                    },
                    onError: { message in
                        errorMessage = message
                        showError = true
                    },
                    durationOverride: elapsedSeconds / 60
                )
            }
            .sheet(isPresented: $showFeelRating) {
                TimerFeelRatingView(
                    skillId: selectedSkill?.id ?? 0,
                    durationMinutes: max(elapsedSeconds / 60, 1),
                    onSave: {
                        onSave?()
                        dismiss()
                    },
                    onDiscard: {
                        dismiss()
                    }
                )
            }
            .sheet(isPresented: $showError) {
                SessionErrorView(
                    message: errorMessage,
                    onRetry: {
                        showError = false
                        showSessionLog = true
                    },
                    onDismiss: {
                        showError = false
                    }
                )
            }
            .onAppear {
                if selectedSkill == nil {
                    selectedSkill = skills.first
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Skill Selector

    private var skillSelector: some View {
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

    // MARK: - Timer Display

    private var timerDisplay: some View {
        VStack(spacing: 12) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(GraftColors.surfaceRaised, lineWidth: 8)
                    .frame(width: 240, height: 240)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                VStack(spacing: 8) {
                    if isRunning || elapsedSeconds > 0 {
                        Text(formattedTime)
                            .font(.system(size: 52, weight: .bold, design: .monospaced))
                            .foregroundColor(GraftColors.textPrimary)
                    } else {
                        Text(formattedTime)
                            .font(.system(size: 52, weight: .bold, design: .monospaced))
                            .foregroundColor(GraftColors.textSecondary)
                    }

                    if let skill = selectedSkill {
                        Text(skill.name)
                            .font(.system(size: 14))
                            .foregroundColor(GraftColors.textSecondary)
                    }
                }
            }

            if isRunning {
                Text(statusText)
                    .font(.system(size: 12))
                    .foregroundColor(GraftColors.accent)
            }
        }
    }

    // MARK: - Preset Selector

    private var presetSelector: some View {
        HStack(spacing: 10) {
            ForEach(presets, id: \.self) { minutes in
                Button {
                    selectedDuration = minutes
                } label: {
                    Text("\(minutes)m")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(selectedDuration == minutes ? .white : GraftColors.textSecondary)
                        .frame(width: 56, height: 40)
                        .background {
                            if selectedDuration == minutes {
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

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if isRunning {
                Button {
                    stopTimer()
                    showFeelRating = true
                } label: {
                    Text("End Session")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Button {
                    startTimer()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Practice")
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
                .disabled(selectedSkill == nil)
            }

            if elapsedSeconds > 0 && !isRunning {
                Button {
                    showSessionLog = true
                } label: {
                    Text("Log This Session")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(GraftColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private var progress: Double {
        guard selectedDuration > 0 else { return 0 }
        let totalSeconds = selectedDuration * 60
        return min(Double(elapsedSeconds) / Double(totalSeconds), 1.0)
    }

    private var formattedTime: String {
        let remaining = max((selectedDuration * 60) - elapsedSeconds, 0)
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var statusText: String {
        let remaining = max((selectedDuration * 60) - elapsedSeconds, 0)
        let minutes = remaining / 60
        if minutes == 0 && remaining > 0 {
            return "Almost done..."
        } else if minutes < 5 {
            return "\(minutes)m left — stay focused"
        }
        return "Stay focused..."
    }

    private func startTimer() {
        guard selectedSkill != nil else {
            errorMessage = "Please select a skill first."
            showError = true
            return
        }
        isRunning = true
        elapsedSeconds = 0

        runningTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] t in
            self.elapsedSeconds += 1
            if self.elapsedSeconds >= self.selectedDuration * 60 {
                t.invalidate()
                self.isRunning = false
                self.showFeelRating = true
            }
        }
    }

    private func stopTimer() {
        isRunning = false
        runningTimer?.invalidate()
    }
}

// MARK: - Timer Feel Rating

struct TimerFeelRatingView: View {
    let skillId: Int64
    let durationMinutes: Int
    let onSave: () -> Void
    let onDiscard: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var feelRating: Int = 3
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                VStack(spacing: 32) {
                    // Session complete header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(GraftColors.success.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(GraftColors.success)
                        }

                        Text("Session Complete!")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(GraftColors.textPrimary)

                        Text(formattedDuration)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(GraftColors.accent)
                    }
                    .padding(.top, 20)

                    // Feel rating
                    VStack(spacing: 16) {
                        Text("How did it feel?")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(GraftColors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)

                        HStack(spacing: 20) {
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
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .foregroundColor(GraftColors.textPrimary)
                            .padding(14)
                            .background(GraftColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Spacer()

                    // Actions
                    VStack(spacing: 12) {
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
                                LinearGradient(colors: [GraftColors.accent, GraftColors.accentMuted], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isSaving)

                        Button {
                            onDiscard()
                            dismiss()
                        } label: {
                            Text("Discard")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(GraftColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDiscard()
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

    private var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    private func saveSession() {
        isSaving = true
        var session = Session(
            skillId: skillId,
            durationMinutes: durationMinutes,
            feelRating: feelRating,
            notes: notes.isEmpty ? nil : notes,
            practicedAt: Date()
        )

        let success = DatabaseService.shared.saveSession(&session)
        if success {
            onSave()
            dismiss()
        } else {
            isSaving = false
            errorMessage = "Could not save your session. Please try again."
            showError = true
        }
    }
}
