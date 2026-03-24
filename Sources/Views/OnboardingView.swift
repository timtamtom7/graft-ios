import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool

    @State private var currentPage = 0

    var body: some View {
        ZStack {
            GraftColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        icon: "hammer.and.wrench",
                        title: "Put in the work.",
                        subtitle: "Mastery isn't born from motivation or talent. It's built in the hours nobody sees — the reps, the drills, the slow accumulation of competence.",
                        accentColor: GraftColors.accent
                    )
                    .tag(0)

                    OnboardingPage(
                        icon: "1.circle",
                        title: "One skill at a time.",
                        subtitle: "Splitting attention is how you get nowhere. Pick one thing. Go deep. When you've built something real there, add another.",
                        accentColor: GraftColors.accent
                    )
                    .tag(1)

                    OnboardingPage(
                        icon: "clock.badge.checkmark",
                        title: "Track your hours.",
                        subtitle: "A practice session isn't complete until it's logged. Five minutes or fifty — it all counts, as long as you write it down.",
                        accentColor: GraftColors.accent
                    )
                    .tag(2)

                    OnboardingPage(
                        icon: "figure.run",
                        title: "Start practicing.",
                        subtitle: "Your first skill is waiting. Pick something you've been meaning to work on — and start today.",
                        accentColor: GraftColors.accent
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicator + button
                VStack(spacing: 24) {
                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? GraftColors.accent : GraftColors.surfaceRaised)
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }

                    if currentPage == 3 {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Get Started")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [GraftColors.accent, GraftColors.accentMuted],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 20)
                    } else {
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            Text("Continue")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(GraftColors.textSecondary)
                        }
                    }
                }
                .padding(.bottom, 48)
            }
        }
        .onTapGesture {
            // Swipe/tap to advance on non-last pages
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding_v1")
        hasCompletedOnboarding = true
    }
}

// MARK: - Onboarding Page

struct OnboardingPage: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 60)

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.2),
                                accentColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(accentColor)
            }

            Spacer(minLength: 40)

            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(GraftColors.textPrimary)
                .multilineTextAlignment(.center)

            Spacer(minLength: 16)

            Text(subtitle)
                .font(.system(size: 16))
                .foregroundColor(GraftColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 32)

            Spacer(minLength: 60)
        }
    }
}
