import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentStep: Int = 0
    @State private var selectedSkillName: String = ""
    @State private var selectedSkillEmoji: String = "🎯"
    @State private var practiceGoalMinutes: Int = 30
    @State private var showLogSession = false
    @State private var loggedFirstSession = false

    private let totalSteps = 3

    // Popular skill suggestions
    private let suggestedSkills: [(emoji: String, name: String)] = [
        ("🎹", "Piano"), ("🎸", "Guitar"), ("💻", "Coding"),
        ("📚", "Reading"), ("🏃", "Running"), ("🎨", "Drawing"),
        ("🥁", "Drums"), ("🎤", "Singing"), ("🏋️", "Weightlifting"),
        ("🧘", "Yoga"), ("🌐", "Language"), ("📝", "Writing"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            progressBar
                .padding(.top, 24)

            // Step content
            TabView(selection: $currentStep) {
                stepOneView.tag(0)
                stepTwoView.tag(1)
                stepThreeView.tag(2)
            }
            .tabViewStyle(.automatic)
            .animation(.easeInOut(duration: 0.3), value: currentStep)

            // Navigation buttons
            navigationButtons
                .padding(.bottom, 24)
        }
        .frame(width: 560, height: 480)
        .background(GraftColors.background)
        .sheet(isPresented: $showLogSession) {
            if let skillId = getOrCreateSkillId() {
                MacLogSessionSheet(skillId: skillId) {
                    loggedFirstSession = true
                }
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? GraftColors.accent : GraftColors.surfaceRaised)
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentStep)
            }
        }
    }

    // MARK: - Step 1: Choose Skill

    private var stepOneView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("What skill do you want to master?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(GraftColors.textPrimary)

                Text("Pick something specific. 'Guitar' beats 'Music'. 'Piano scales' beats 'Piano'.")
                    .font(.subheadline)
                    .foregroundColor(GraftColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }
            .padding(.top, 32)

            // Custom skill input
            VStack(alignment: .leading, spacing: 12) {
                Text("YOUR SKILL")
                    .font(.caption)
                    .foregroundColor(GraftColors.textSecondary)

                HStack(spacing: 12) {
                    TextField("🎯", text: $selectedSkillEmoji)
                        .font(.title2)
                        .frame(width: 52, height: 48)
                        .multilineTextAlignment(.center)
                        .background(GraftColors.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    TextField("e.g. Piano scales, Spanish verbs...", text: $selectedSkillName)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundColor(GraftColors.textPrimary)
                        .padding(12)
                        .background(GraftColors.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .frame(maxWidth: 380)

            // Suggestions
            VStack(alignment: .leading, spacing: 10) {
                Text("Or choose from suggestions:")
                    .font(.caption)
                    .foregroundColor(GraftColors.textSecondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                    ForEach(suggestedSkills, id: \.name) { skill in
                        Button {
                            selectedSkillEmoji = skill.emoji
                            selectedSkillName = skill.name
                        } label: {
                            VStack(spacing: 4) {
                                Text(skill.emoji)
                                    .font(.title2)
                                Text(skill.name)
                                    .font(.caption2)
                                    .foregroundColor(
                                        selectedSkillName == skill.name && selectedSkillEmoji == skill.emoji
                                            ? GraftColors.accent : GraftColors.textSecondary
                                    )
                            }
                            .frame(width: 64, height: 56)
                            .background(
                                selectedSkillName == skill.name && selectedSkillEmoji == skill.emoji
                                    ? GraftColors.accent.opacity(0.15)
                                    : GraftColors.surfaceRaised
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        selectedSkillName == skill.name && selectedSkillEmoji == skill.emoji
                                            ? GraftColors.accent : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(skill.emoji) \(skill.name)")
                        .accessibilityAddTraits(selectedSkillName == skill.name ? .isSelected : [])
                    }
                }
            }
            .frame(maxWidth: 380)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Step 2: Set Goal

    private var stepTwoView: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("Set a practice goal")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(GraftColors.textPrimary)

                Text("How long do you want to practice per session? You can always change this later.")
                    .font(.subheadline)
                    .foregroundColor(GraftColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }
            .padding(.top, 32)

            // Goal picker
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    Picker("Minutes", selection: $practiceGoalMinutes) {
                        ForEach([15, 20, 25, 30, 45, 60, 90, 120], id: \.self) { mins in
                            Text("\(mins) min").tag(mins)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
                .padding(16)
                .background(GraftColors.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Quick presets
                HStack(spacing: 10) {
                    ForEach([15, 30, 60], id: \.self) { mins in
                        Button {
                            practiceGoalMinutes = mins
                        } label: {
                            Text("\(mins)m")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(
                                    practiceGoalMinutes == mins
                                        ? GraftColors.textOnAccent
                                        : GraftColors.textSecondary
                                )
                                .frame(width: 64, height: 36)
                                .background(
                                    practiceGoalMinutes == mins
                                        ? GraftColors.accent
                                        : GraftColors.surfaceRaised
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(mins) minutes per session")
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: 380)

            // Insight
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(GraftColors.amber)
                    .frame(width: 20)

                Text("Research shows that 30-minute focused sessions with a clear goal are more effective than longer, unfocused practice.")
                    .font(.caption)
                    .foregroundColor(GraftColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(GraftColors.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .frame(maxWidth: 380)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Step 3: Quick Tutorial

    private var stepThreeView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Log your first session")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(GraftColors.textPrimary)

                Text("Ready to start? Log your first practice session right now — it takes under 10 seconds.")
                    .font(.subheadline)
                    .foregroundColor(GraftColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            .padding(.top, 32)

            if loggedFirstSession {
                // Success state
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(GraftColors.success)

                    Text("First session logged!")
                        .font(.headline)
                        .foregroundColor(GraftColors.textPrimary)

                    Text("You're all set. Keep practicing consistently and check back to see your progress grow.")
                        .font(.subheadline)
                        .foregroundColor(GraftColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 340)
                }
                .padding(.vertical, 32)
            } else {
                // Skill summary card
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Text(selectedSkillEmoji)
                            .font(.system(size: 40))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedSkillName.isEmpty ? "Your Skill" : selectedSkillName)
                                .font(.headline)
                                .foregroundColor(GraftColors.textPrimary)

                            Text("Goal: \(practiceGoalMinutes) min per session")
                                .font(.caption)
                                .foregroundColor(GraftColors.textSecondary)
                        }

                        Spacer()
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(GraftColors.streakOrange)
                        Text("Track your streak to build consistency")
                            .font(.caption)
                            .foregroundColor(GraftColors.textSecondary)
                    }
                }
                .padding(20)
                .background(GraftColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .frame(maxWidth: 380)

                Button {
                    showLogSession = true
                } label: {
                    Label("Log First Session", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(GraftColors.textOnAccent)
                        .frame(maxWidth: 380)
                        .frame(height: 48)
                }
                .buttonStyle(.plain)
                .background(GraftColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel("Log First Session")
                .accessibilityHint("Opens a sheet to log your first practice session")
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(GraftColors.textSecondary)
                .accessibilityLabel("Go back")
            } else {
                Color.clear.frame(width: 60)
            }

            Spacer()

            Text("\(currentStep + 1) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(GraftColors.textSecondary)

            Spacer()

            if currentStep < totalSteps - 1 {
                Button("Next") {
                    withAnimation {
                        currentStep += 1
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(GraftColors.accent)
                .font(.headline)
                .frame(width: 80)
                .padding(.vertical, 8)
                .background(GraftColors.accent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(currentStep == 0 && selectedSkillName.isEmpty)
                .accessibilityLabel("Next step")
            } else if loggedFirstSession {
                Button("Get Started") {
                    completeOnboarding()
                }
                .buttonStyle(.plain)
                .foregroundColor(GraftColors.textOnAccent)
                .font(.headline)
                .frame(width: 120, height: 36)
                .background(GraftColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Get Started")
            } else {
                Button("Skip for now") {
                    completeOnboarding()
                }
                .buttonStyle(.plain)
                .foregroundColor(GraftColors.textSecondary)
                .font(.subheadline)
                .accessibilityLabel("Skip onboarding")
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func getOrCreateSkillId() -> Int64? {
        guard !selectedSkillName.isEmpty else { return nil }

        // Check if skill already exists
        let existingSkills = DatabaseService.shared.getAllSkills()
        if let existing = existingSkills.first(where: { $0.name == selectedSkillName }) {
            return existing.id
        }

        // Create new skill
        var skill = Skill(name: selectedSkillName, emoji: selectedSkillEmoji)
        if DatabaseService.shared.saveSkill(&skill) {
            return skill.id
        }
        return nil
    }

    private func completeOnboarding() {
        // Save onboarding completion to UserDefaults
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        hasCompletedOnboarding = true
    }
}
