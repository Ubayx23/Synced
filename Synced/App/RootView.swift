import SwiftUI

/// Top-level router: shows onboarding until the user finishes it, then the main tabs.
/// `hasCompletedOnboarding` persists across launches via `UserDefaults`.
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingFlow()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: hasCompletedOnboarding)
        .preferredColorScheme(.dark)
    }
}
