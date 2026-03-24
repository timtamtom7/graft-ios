import SwiftUI

struct SkillPickerSheet: View {
    let onSave: () -> Void
    var onLimitReached: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var customSkillName: String = ""
    @State private var customSkillEmoji: String = "🎯"
    @State private var showCustomInput: Bool = false

    private let maxFreeSkills = 1
    private let currentSkillCount = DatabaseService.shared.getAllSkills().filter { !$0.isActive }.count + 1

    private let commonSkills: [(name: String, emoji: String)] = [
        ("Guitar", "🎸"), ("Piano", "🎹"), ("Coding", "💻"), ("Language", "🗣"),
        ("Chess", "♟️"), ("Drawing", "🎨"), ("Basketball", "🏀"), ("Tennis", "🎾"),
        ("Running", "🏃"), ("Reading", "📚"), ("Writing", "✍️"), ("Cooking", "🍳"),
        ("Photography", "📷"), ("Yoga", "🧘"), ("Singing", "🎤"), ("Drums", "🥁"),
        ("Woodworking", "🪚"), ("Gardening", "🌱"), ("Calligraphy", "✒️"), ("Meditation", "🧠")
    ]

    private var filteredSkills: [(name: String, emoji: String)] {
        if searchText.isEmpty {
            return commonSkills
        }
        return commonSkills.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    if showCustomInput {
                        customSkillInput
                    } else {
                        skillList
                    }
                }
            }
            .navigationTitle("Choose Skill")
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
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCustomInput = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundColor(GraftColors.accent)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Skill List

    private var skillList: some View {
        VStack(spacing: 0) {
            TextField("Search skills...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundColor(GraftColors.textPrimary)
                .padding(14)
                .background(GraftColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredSkills, id: \.name) { skill in
                        skillRow(name: skill.name, emoji: skill.emoji) {
                            selectSkill(name: skill.name, emoji: skill.emoji)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    private func skillRow(name: String, emoji: String, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text(emoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(GraftColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(GraftColors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(GraftColors.textSecondary)
            }
            .padding(14)
            .background(GraftColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Custom Skill Input

    private var customSkillInput: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                TextField("Skill name", text: $customSkillName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .foregroundColor(GraftColors.textPrimary)
                    .padding(14)
                    .background(GraftColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Menu {
                    ForEach(["🎯", "⭐️", "🔥", "💪", "🌟", "✨", "💡", "🎨", "🎸", "🎹", "💻", "🗣"], id: \.self) { emoji in
                        Button(emoji) {
                            customSkillEmoji = emoji
                        }
                    }
                } label: {
                    Text(customSkillEmoji)
                        .font(.system(size: 32))
                        .frame(width: 56, height: 56)
                        .background(GraftColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Button {
                if !customSkillName.trimmingCharacters(in: .whitespaces).isEmpty {
                    selectSkill(name: customSkillName.trimmingCharacters(in: .whitespaces), emoji: customSkillEmoji)
                }
            } label: {
                Text("Add Skill")
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
            .disabled(customSkillName.trimmingCharacters(in: .whitespaces).isEmpty)

            Button("Back to list") {
                showCustomInput = false
                customSkillName = ""
            }
            .font(.system(size: 13))
            .foregroundColor(GraftColors.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func selectSkill(name: String, emoji: String) {
        // Check skill limit (Free tier = 1 skill)
        let activeSkills = DatabaseService.shared.getAllSkills()
        let activeCount = activeSkills.count

        if activeCount >= maxFreeSkills {
            onLimitReached?()
            dismiss()
            return
        }

        DatabaseService.shared.deactivateAllSkills()
        var skill = Skill(name: name, emoji: emoji, isActive: true)
        DatabaseService.shared.saveSkill(&skill)
        onSave()
        dismiss()
    }
}
