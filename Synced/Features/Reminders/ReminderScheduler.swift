import Foundation
import OSLog
import Supabase
import UserNotifications

/// Local daily reminder to log a session. No APNs and no server: requests
/// are scheduled on device and fire even when the app is not running.
///
/// Rather than one repeating trigger (which cannot skip a single day), the
/// app keeps one-shot reminders for the next `horizonDays` days, each with a
/// per-day identifier. Every reschedule rewrites them from current data:
/// days already logged get no reminder, days with a planned session get a
/// planned-session body, and the rest get the default body. Rescheduling
/// runs on foreground, after plan, log, or delete, and on time changes, so
/// content stays fresh and the reminders keep going for two weeks even if
/// the app is not opened.
enum ReminderScheduler {
    enum Keys {
        static let enabled = "dailyReminderEnabled"
        static let hour = "dailyReminderHour"
        static let minute = "dailyReminderMinute"
    }

    static let defaultHour = 20
    static let defaultMinute = 0
    static let horizonDays = 14
    static let deepLinkKey = "deepLink"
    static let deepLinkLog = "log"
    private static let idPrefix = "synced.daily.reminder"

    private static let log = Logger(subsystem: "page.synced.app", category: "Reminders")
    private static var center: UNUserNotificationCenter { .current() }

    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: Keys.enabled) }

    /// Stored as separate hour and minute so the reminder follows the local
    /// clock after a timezone change.
    static var time: (hour: Int, minute: Int) {
        let defaults = UserDefaults.standard
        let hour = defaults.object(forKey: Keys.hour) as? Int ?? defaultHour
        let minute = defaults.object(forKey: Keys.minute) as? Int ?? defaultMinute
        return (hour, minute)
    }

    // MARK: - Permission

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Prompts only when iOS has never asked. Returns whether reminders can
    /// be delivered.
    static func requestPermissionIfNeeded() async -> Bool {
        switch await authorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        default:
            return false
        }
    }

    // MARK: - Scheduling

    /// Rewrites pending reminders from the stored preference and current
    /// session data. Safe to call often; identifiers are per day, so
    /// overlapping calls replace rather than duplicate.
    static func reschedule() async {
        guard isEnabled else {
            await cancelAll()
            return
        }
        guard [.authorized, .provisional, .ephemeral].contains(await authorizationStatus()) else {
            await cancelAll()
            return
        }

        let cal = WeekStore.calendar
        let (hour, minute) = time
        let now = Date()
        let today = cal.startOfDay(for: now)
        let days = (0..<horizonDays).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
        let plans = await dayPlans(from: today, days: horizonDays)

        var wanted: [UNNotificationRequest] = []
        for day in days {
            guard let fire = cal.date(bySettingHour: hour, minute: minute, second: 0, of: day), fire > now else { continue }
            let key = WeekStore.dayFormatter.string(from: day)
            let state = plans[key] ?? .open
            guard let body = body(for: state) else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Synced"
            content.body = body
            content.sound = .default
            content.userInfo = [deepLinkKey: deepLinkLog]

            let components = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            wanted.append(UNNotificationRequest(identifier: "\(idPrefix).\(key)", content: content, trigger: trigger))
        }

        // Drop pending reminders that are no longer wanted, then add or
        // replace the rest.
        let wantedIDs = Set(wanted.map(\.identifier))
        let stale = await pendingReminderIDs().filter { !wantedIDs.contains($0) }
        center.removePendingNotificationRequests(withIdentifiers: stale)
        for request in wanted {
            do {
                try await center.add(request)
            } catch {
                log.error("Reminder schedule failed: \(String(describing: error), privacy: .public)")
            }
        }
    }

    static func cancelAll() async {
        center.removePendingNotificationRequests(withIdentifiers: await pendingReminderIDs())
    }

    /// Sign out clears the preference so the next account starts fresh.
    static func reset() async {
        UserDefaults.standard.removeObject(forKey: Keys.enabled)
        UserDefaults.standard.removeObject(forKey: Keys.hour)
        UserDefaults.standard.removeObject(forKey: Keys.minute)
        await cancelAll()
    }

    private static func pendingReminderIDs() async -> [String] {
        await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(idPrefix) }
    }

    // MARK: - Content

    enum DayState {
        case open
        case planned(SessionType)
        case logged
    }

    /// nil means already logged: no reminder that day.
    static func body(for state: DayState) -> String? {
        switch state {
        case .logged:
            return nil
        case .planned(.rest):
            return "You planned a rest day today. Log it?"
        case .planned(let type):
            return "You planned a \(type.title.lowercased()) for today. Log it?"
        case .open:
            return "Log today's session."
        }
    }

    /// Per-day state for the scheduling window, keyed by yyyy-MM-dd. A
    /// logged session wins over a plan; among plans, the earliest created
    /// wins. On a failed fetch every day falls back to the default body.
    private static func dayPlans(from start: Date, days: Int) async -> [String: DayState] {
        struct Row: Decodable {
            let session_type: String?
            let scheduled_date: String?
            let is_planned: Bool?
        }
        guard let end = WeekStore.calendar.date(byAdding: .day, value: days - 1, to: start) else { return [:] }
        do {
            let userID = try await supabase.auth.session.user.id
            let rows: [Row] = try await supabase
                .from("sessions")
                .select("session_type, scheduled_date, is_planned")
                .eq("user_id", value: userID.uuidString)
                .gte("scheduled_date", value: WeekStore.dayFormatter.string(from: start))
                .lte("scheduled_date", value: WeekStore.dayFormatter.string(from: end))
                .order("created_at", ascending: true)
                .execute()
                .value
            var result: [String: DayState] = [:]
            for row in rows {
                guard let date = row.scheduled_date.map({ String($0.prefix(10)) }) else { continue }
                if row.is_planned == false {
                    result[date] = .logged
                } else if case .logged = result[date] {
                    continue
                } else if result[date] == nil, let type = row.session_type.flatMap(SessionType.init(rawValue:)) {
                    result[date] = .planned(type)
                }
            }
            return result
        } catch {
            log.error("Reminder content fetch failed: \(String(describing: error), privacy: .public)")
            return [:]
        }
    }
}
