import SwiftUI

/// Top-level router: launch screen on cold start, then auth or the Week view
/// based on the live Supabase session held in `SessionStore`.
struct RootView: View {
    @State private var session = SessionStore()
    @State private var showingLaunch: Bool = true
    @State private var showingSignIn: Bool = false

    var body: some View {
        ZStack {
            if showingLaunch || session.phase == .loading {
                LaunchScreen { showingLaunch = false }
                    .transition(.opacity)
            } else if session.phase == .signedIn {
                WeekView()
                    .transition(.opacity)
            } else {
                authEntry
                    .transition(.opacity)
            }
        }
        .environment(session)
        .task { await session.bootstrap() }
        .onChange(of: session.phase) { _, _ in showingSignIn = false }
        .animation(.easeInOut(duration: 0.35), value: showingLaunch)
        .animation(.easeInOut(duration: 0.35), value: session.phase)
        .preferredColorScheme(.dark)
    }

    /// Sign up by default; returning users open SignInView as a cover.
    private var authEntry: some View {
        ZStack {
            SYN.bg.ignoresSafeArea()
            SignUpView(
                onSignIn: { showingSignIn = true },
                onSuccess: { session.markSignedIn() }
            )
        }
        .fullScreenCover(isPresented: $showingSignIn) {
            SignInView(onClose: { showingSignIn = false })
                .environment(session)
        }
    }
}
