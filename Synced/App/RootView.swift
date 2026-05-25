import SwiftUI

/// Top-level router: launch screen on cold start, then onboarding or tabs
/// based on the live Supabase session held in `SessionStore`.
struct RootView: View {
    @State private var session = SessionStore()
    @State private var showingLaunch: Bool = true

    var body: some View {
        ZStack {
            if showingLaunch || session.phase == .loading {
                LaunchScreen { showingLaunch = false }
                    .transition(.opacity)
            } else if session.phase == .signedIn {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingFlow()
                    .transition(.opacity)
            }
        }
        .environment(session)
        .task { await session.bootstrap() }
        .animation(.easeInOut(duration: 0.35), value: showingLaunch)
        .animation(.easeInOut(duration: 0.35), value: session.phase)
        .preferredColorScheme(.dark)
    }
}
