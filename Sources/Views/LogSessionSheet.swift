import SwiftUI

struct LogSessionSheet: View {
    let skillId: Int64
    let onSave: () -> Void
    var onError: ((String) -> Void)?
    var durationOverride: Int? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var hours: Int = 0
    @State private var minutes: Int = 30
    @State private var feelRating: Int = 3
    @State private var notes: String = ""
    @State private var isSaving: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        durationSection
                        feelSection
                        notesSection
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GraftColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(GraftColors.textSecondary)
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSession()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isSaving ? GraftColors.textSecondary : GraftColors.accent)
                    .disabled(totalMinutes == 0 || isSaving)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if let override = durationOverride {
                hours = override / 60
                minutes = override % 60
            }
        }
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        VStack(spacing: 16) {
            Text("Duration")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(GraftColors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)

            HStack(spacing: 0) {
                Picker("Hours", selection: $hours) {
                    ForEach(0..<9) { h in
                        Text("\(h)h").tag(h)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
                .clipped()

                Picker("Minutes", selection: $minutes) {
                    ForEach(0..<60) { m in
                        if m % 5 == 0 {
                            Text("\(m)m").tag(m)
                        }
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

    // MARK: - Feel Section

    private var feelSection: some View {
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
                        .strokeBorder(
                            rating == feelRating ? GraftColors.accent : Color.clear,
                            lineWidth: 2
                        )
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

    // MARK: - Notes Section

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

    // MARK: - Helpers

    private var totalMinutes: Int {
        hours * 60 + minutes
    }

    private var formattedDuration: String {
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    private func saveSession() {
        guard totalMinutes > 0 else { return }
        isSaving = true

        var session = Session(
            skillId: skillId,
            durationMinutes: totalMinutes,
            feelRating: feelRating,
            notes: notes.isEmpty ? nil : notes,
            practicedAt: Date()
        )

        // Attempt save
        let success = DatabaseService.shared.saveSession(&session)

        if success {
            onSave()
            dismiss()
        } else {
            isSaving = false
            onError?("Could not save your session. Please try again.")
        }
    }
}
