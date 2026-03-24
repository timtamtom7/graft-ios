import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding_v1") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .background(GraftColors.background)
    }
}
