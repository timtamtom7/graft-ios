import SwiftUI

struct MacLogSessionSheet: View {
    let skillId: Int64
    let onSave: () -> Void
    var onError: ((String) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var hours: Int = 0
    @State private var minutes: Int = 30
    @State private var feelRating: Int = 3
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @State private var isSaving: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Log Session")
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

            Divider()
                .background(GraftColors.surfaceRaised)

            ScrollView {
                VStack(spacing: 28) {
                    durationSection
                    feelSection
                    dateSection
                    notesSection
                }
                .padding(24)
            }

            Divider()
                .background(GraftColors.surfaceRaised)

            // Save button
            HStack {
                Spacer()
                Button {
                    saveSession()
                } label: {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 120, height: 36)
                    } else {
                        Text("Save Session")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 140, height: 36)
                    }
                }
                .buttonStyle(.plain)
                .background(totalMinutes > 0 ? GraftColors.accent : GraftColors.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(totalMinutes == 0 || isSaving)
                .padding(20)
            }
            .background(GraftColors.surface)
        }
        .frame(width: 440, height: 520)
        .background(GraftColors.background)
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Duration")

            HStack(spacing: 0) {
                Picker("Hours", selection: $hours) {
                    ForEach(0..<9) { h in
                        Text("\(h) hr").tag(h)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)

                Picker("Minutes", selection: $minutes) {
                    ForEach([0, 5, 10, 15, 20, 25, 30, 45], id: \.self) { m in
                        Text("\(m) min").tag(m)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 110)

                Spacer()

                Text(totalDurationText)
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundColor(GraftColors.accent)
            }
            .padding(16)
            .background(GraftColors.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var totalMinutes: Int { hours * 60 + minutes }

    private var totalDurationText: String {
        if totalMinutes == 0 { return "0m" }
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    // MARK: - Feel Section

    private var feelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("How did it feel?")

            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        feelRating = rating
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(rating <= feelRating ? GraftColors.accent : GraftColors.surfaceRaised)
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Text(feelEmoji(for: rating))
                                        .font(.title3)
                                }
                            Text(feelLabel(for: rating))
                                .font(.caption2)
                                .foregroundColor(rating == feelRating ? GraftColors.textPrimary : GraftColors.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(16)
            .background(GraftColors.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func feelEmoji(for rating: Int) -> String {
        switch rating {
        case 1: return "😞"; case 2: return "😐"; case 3: return "🙂"; case 4: return "😊"; default: return "🤩"
        }
    }

    private func feelLabel(for rating: Int) -> String {
        switch rating {
        case 1: return "Rough"; case 2: return "Meh"; case 3: return "Okay"; case 4: return "Good"; default: return "Great"
        }
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Date")

            DatePicker(
                "Practiced on",
                selection: $date,
                in: ...Date(),
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .padding(16)
            .background(GraftColors.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Notes (optional)")

            TextField("What did you work on?", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundColor(GraftColors.textPrimary)
                .lineLimit(3...6)
                .padding(16)
                .background(GraftColors.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(GraftColors.textSecondary)
            .textCase(.uppercase)
            .tracking(1.2)
    }

    // MARK: - Save

    private func saveSession() {
        guard totalMinutes > 0 else { return }
        isSaving = true

        var session = Session(
            skillId: skillId,
            durationMinutes: totalMinutes,
            feelRating: feelRating,
            notes: notes.isEmpty ? nil : notes,
            practicedAt: date
        )
        let success = DatabaseService.shared.saveSession(&session)
        isSaving = false
        if success {
            onSave()
            dismiss()
        } else {
            onError?("Failed to save session")
        }
    }
}
