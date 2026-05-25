import Foundation
import Observation

/// Single source of truth for auth state. RootView reads `phase` to decide
/// what to show; sign-up, sign-in, and reset onboarding call into this to
/// flip the gate.
@Observable
final class SessionStore {
    enum Phase {
        case loading
        case signedOut
        case signedIn
    }

    var phase: Phase = .loading

    /// Reads the persisted Supabase session at launch and routes accordingly.
    func bootstrap() async {
        let session = try? await supabase.auth.session
        await MainActor.run {
            phase = session == nil ? .signedOut : .signedIn
        }
    }

    @MainActor
    func markSignedIn() {
        phase = .signedIn
    }

    func signOut() async {
        try? await supabase.auth.signOut()
        await MainActor.run {
            phase = .signedOut
        }
    }
}
