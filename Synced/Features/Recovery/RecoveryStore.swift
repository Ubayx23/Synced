import Foundation
import Observation
import OSLog
import Supabase
import SwiftUI

/// Three states read at a glance: one cyan hue that dims to gray as a
/// muscle gets more recently worked.
enum RecoveryState {
    /// 5 or more days since trained, or not trained in the window.
    case ready
    /// 2 to 4 days since trained.
    case recovering
    /// Trained today or yesterday.
    case worked

    init(daysSince: Int?) {
        switch daysSince {
        case .some(let days) where days <= 1: self = .worked
        case .some(let days) where days <= 4: self = .recovering
        default: self = .ready
        }
    }

    var color: Color {
        switch self {
        case .ready:      return SYN.muscleReady
        case .recovering: return SYN.muscleRecovering
        case .worked:     return SYN.muscleWorked
        }
    }
}

/// Days since each muscle group was last trained, from logged sessions in
/// the last 14 days. Legacy values ("full_body", "biceps", "triceps",
/// "forearms") count through `MuscleGroup.expand`.
@Observable
final class RecoveryStore {
    static let windowDays = 14

    /// Keyed by group; missing means not trained in the window.
    private(set) var daysSince: [MuscleGroup: Int] = [:]
    /// Any logged session in the window, of any type.
    private(set) var hasSessions = false
    /// Days since the most recent logged climb or lift (not just lifts with
    /// muscle groups; rest days do not count); nil when none in the window.
    private(set) var daysSinceLastWorkout: Int?
    private(set) var loaded = false

    private static let log = Logger(subsystem: "page.synced.app", category: "RecoveryStore")

    func state(for group: MuscleGroup) -> RecoveryState {
        RecoveryState(daysSince: daysSince[group])
    }

    var freshCount: Int {
        MuscleGroup.allCases.filter { state(for: $0) == .ready }.count
    }

    @MainActor
    func load() async {
        struct Row: Decodable {
            let session_type: String?
            let scheduled_date: String?
            let muscle_groups: [String]?
        }
        let cal = WeekStore.calendar
        let today = cal.startOfDay(for: Date())
        guard let start = cal.date(byAdding: .day, value: -(Self.windowDays - 1), to: today) else { return }
        do {
            let userID = try await supabase.auth.session.user.id
            // Up to today only: a future-dated log has no recovery meaning yet.
            let rows: [Row] = try await supabase
                .from("sessions")
                .select("session_type, scheduled_date, muscle_groups")
                .eq("user_id", value: userID.uuidString)
                .eq("is_planned", value: false)
                .gte("scheduled_date", value: WeekStore.dayFormatter.string(from: start))
                .lte("scheduled_date", value: WeekStore.dayFormatter.string(from: today))
                .execute()
                .value

            var result: [MuscleGroup: Int] = [:]
            var mostRecent: Int?
            for row in rows {
                guard
                    let raw = row.scheduled_date,
                    let date = WeekStore.dayFormatter.date(from: String(raw.prefix(10))),
                    let days = cal.dateComponents([.day], from: date, to: today).day
                else { continue }
                if row.session_type != SessionType.rest.rawValue {
                    mostRecent = min(mostRecent ?? days, days)
                }
                for group in MuscleGroup.expand(row.muscle_groups ?? []) {
                    result[group] = min(result[group] ?? days, days)
                }
            }
            daysSince = result
            daysSinceLastWorkout = mostRecent
            hasSessions = !rows.isEmpty
            loaded = true
        } catch is CancellationError {
            // Interrupted by a refresh or view teardown; not a failure.
        } catch {
            Self.log.error("Recovery load failed: \(String(describing: error), privacy: .public)")
            loaded = true
        }
    }
}
