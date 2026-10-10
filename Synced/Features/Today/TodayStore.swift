import Foundation
import Observation
import OSLog

/// Data behind the Today screen: the current week through tomorrow (for
/// today, tomorrow, and the week stats) and the most recent logged session
/// (for the Last and Last Note cards). Everything else is derived here.
@Observable
final class TodayStore {
    /// Holds the current week and tomorrow. Also the store the Plan and Log
    /// sheets write to for days in that range.
    let week = WeekStore()
    /// Most recent logged session on or before today.
    private(set) var lastSession: Session?

    private static let log = Logger(subsystem: "page.synced.app", category: "TodayStore")

    private var cal: Calendar { WeekStore.calendar }

    /// Monday to Sunday of the current week, plus tomorrow when tomorrow is
    /// next Monday.
    static func loadRange(today: Date) -> [Date] {
        let cal = WeekStore.calendar
        let days = WeekStore.weekDays(containing: today)
        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: today)) else { return days }
        if let last = days.last, tomorrow > last { return days + [tomorrow] }
        return days
    }

    @MainActor
    func load(today: Date) async {
        await week.load(week: Self.loadRange(today: today))
        do {
            lastSession = try await WeekStore.lastLogged(onOrBefore: today)
        } catch is CancellationError {
        } catch let error as URLError where error.code == .cancelled {
        } catch {
            Self.log.error("Last session failed: \(String(describing: error), privacy: .public)")
        }
    }

    // MARK: - Today and tomorrow

    func sessions(on day: Date) -> [Session] { week.sessions(on: day) }

    /// What the hero card is about: today's first planned session, or
    /// today's first logged one when nothing is left to log.
    func heroSession(today: Date) -> Session? {
        let list = sessions(on: today)
        return list.first { $0.isPlanned } ?? list.first
    }

    func tomorrowSession(today: Date) -> Session? {
        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: today) else { return nil }
        let list = sessions(on: tomorrow)
        return list.first { $0.isPlanned } ?? list.first
    }

    // MARK: - This week

    /// Logged sessions in the current week up to today.
    func loggedThisWeek(today: Date) -> [Session] {
        let days = WeekStore.weekDays(containing: today)
        guard let start = days.first else { return [] }
        let end = cal.startOfDay(for: today)
        return week.sessions.filter { !$0.isPlanned && $0.date >= start && $0.date <= end }
    }

    func climbsThisWeek(today: Date) -> Int {
        loggedThisWeek(today: today).filter { $0.type == .climb }.count
    }

    func liftsThisWeek(today: Date) -> Int {
        loggedThisWeek(today: today).filter { $0.type == .lift }.count
    }

    /// Weight times reps across every logged set this week. Bodyweight sets
    /// (0 lbs) add nothing.
    func volumeThisWeek(today: Date) -> Double {
        loggedThisWeek(today: today)
            .filter { $0.type == .lift }
            .flatMap(\.exercises)
            .flatMap(\.sets)
            .reduce(0) { $0 + $1.weightLbs * Double($1.reps) }
    }

    // MARK: - Last note

    /// The note on the most recent logged session, when it has one.
    var lastNote: String? { lastSession?.notes }
}

extension Session {
    /// Days with a logged climb or lift count as trained; rest does not.
    var countsAsTrained: Bool { !isPlanned && type != .rest }
}

extension Date {
    /// "Today", "Yesterday", "3 days ago" within a week, else "Oct 1".
    func relativeDayLabel(today: Date = Date()) -> String {
        let cal = WeekStore.calendar
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: self), to: cal.startOfDay(for: today)).day ?? 0
        switch days {
        case 0:      return "Today"
        case 1:      return "Yesterday"
        case 2...6:  return "\(days) days ago"
        case -1:     return "Tomorrow"
        default:     return formatted(.dateTime.month(.abbreviated).day())
        }
    }
}
