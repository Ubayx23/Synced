import SwiftUI

/// Top-level router: launch screen on cold start, then Welcome (signed out)
/// or the tab bar (signed in) based on the live Supabase session held in
/// `SessionStore`.
struct RootView: View {
    @State private var session = SessionStore()
    @State private var showingLaunch: Bool = true
    @State private var authPath: [AuthRoute] = []
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            if showingLaunch || session.phase == .loading {
                LaunchScreen { showingLaunch = false }
                    .transition(.opacity)
            } else if session.phase == .signedIn {
                MainTabView()
                    .transition(.opacity)
            } else {
                authEntry
                    .transition(.opacity)
            }
        }
        .environment(session)
        .task { await session.bootstrap() }
        // Signing out lands on Welcome, not on whichever auth screen was last open.
        .onChange(of: session.phase) { _, phase in
            authPath = []
            switch phase {
            // Reminders belong to the signed-in account; the next one starts fresh.
            case .signedOut: Task { await ReminderScheduler.reset() }
            case .signedIn:  Task { await ReminderScheduler.reschedule() }
            case .loading:   break
            }
        }
        // Back in the foreground: refresh reminder content for the new day
        // and anything logged elsewhere.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, session.phase == .signedIn {
                Task { await ReminderScheduler.reschedule() }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showingLaunch)
        .animation(.easeInOut(duration: 0.35), value: session.phase)
        .preferredColorScheme(.dark)
    }

    /// Welcome is the root; sign up and sign in are pushed on top of it.
    /// Each auth screen has its own back chevron, so the nav bar stays hidden.
    private var authEntry: some View {
        NavigationStack(path: $authPath) {
            WelcomeView(
                onCreateAccount: { authPath = [.signUp] },
                onSignIn: { authPath = [.signIn] }
            )
            .authScreen()
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .signUp:
                    SignUpView(
                        onBack: { authPath = [] },
                        onSignIn: { authPath = [.signIn] },
                        onSuccess: { session.markSignedIn() }
                    )
                    .authScreen()
                case .signIn:
                    SignInView(
                        onClose: { authPath = [] },
                        onCreateAccount: { authPath = [.signUp] }
                    )
                    .authScreen()
                }
            }
        }
    }
}

private enum AuthRoute: Hashable {
    case signUp, signIn
}

private extension View {
    func authScreen() -> some View {
        self
            .background(SYN.bg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
    }
}
