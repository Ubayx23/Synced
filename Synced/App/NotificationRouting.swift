import Observation
import UserNotifications

/// App-wide routing flags set from outside SwiftUI, such as a tapped
/// notification. Views observe and clear them once handled.
@Observable
final class AppRouter {
    static let shared = AppRouter()

    /// True when a reminder was tapped and the Log sheet for today should
    /// open. WeekView consumes it.
    var pendingLogFromReminder = false
}

/// Receives notification taps and shows reminders that arrive while the app
/// is open. Registered as the notification center delegate in SyncedApp.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let link = response.notification.request.content.userInfo[ReminderScheduler.deepLinkKey] as? String
        guard link == ReminderScheduler.deepLinkLog else { return }
        await MainActor.run { AppRouter.shared.pendingLogFromReminder = true }
    }
}
