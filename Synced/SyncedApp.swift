import SwiftUI

@main
struct SyncedApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingFlow()
                .preferredColorScheme(.dark)
                .statusBarHidden(false)
        }
    }
}
