import SwiftUI
import UserNotifications

@main
struct SyncedApp: App {
    init() {
        // Set before launch finishes so a tap that cold-launches the app
        // still reaches the delegate.
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .statusBarHidden(false)
        }
    }
}
