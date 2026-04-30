import SwiftUI

/// Top-level router: launch screen on cold start, then onboarding or tabs
/// based on the persistent `hasCompletedOnboarding` flag.
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showingLaunch: Bool = true

    var body: some View {
        ZStack {
            if showingLaunch {
                LaunchScreen { showingLaunch = false }
                    .transition(.opacity)
            } else if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingFlow()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showingLaunch)
        .animation(.easeInOut(duration: 0.35), value: hasCompletedOnboarding)
        .preferredColorScheme(.dark)
    }
}
