import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GraftColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        LiquidGlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("About Graft")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(GraftColors.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(1.2)

                                Text("Put in the work.")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(GraftColors.textPrimary)

                                Text("Graft is a simple practice tracker for people learning a skill. No streaks, no gamification — just honest tracking of the time you put in.")
                                    .font(.system(size: 14))
                                    .foregroundColor(GraftColors.textSecondary)
                                    .lineSpacing(4)
                            }
                            .padding(20)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        LiquidGlassCard {
                            HStack {
                                Text("Version")
                                    .font(.system(size: 15))
                                    .foregroundColor(GraftColors.textPrimary)
                                Spacer()
                                Text("1.0.0")
                                    .font(.system(size: 15))
                                    .foregroundColor(GraftColors.textSecondary)
                            }
                            .padding(20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
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
        }
    }
}
