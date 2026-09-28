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

/// Days since each muscle was last trained, from logged sessions in the last
/// 14 days, up to today.
///
/// Each logged exercise marks muscles in this order of preference:
/// 1. its ExerciseCatalog entry (primary and secondary count equally),
/// 2. its own muscle_group tag, expanded to every muscle in that group,
/// 3. the session's muscle_groups, expanded the same way.
/// Sessions with no exercises use the session's muscle_groups. Legacy group
/// values ("full_body", "biceps", "triceps", "forearms") read through
/// `MuscleGroup.expand`.
@Observable
final class RecoveryStore {
    static let windowDays = 14

    /// Keyed by muscle; missing means not trained in the window.
    private(set) var daysSince: [TrainedMuscle: Int] = [:]
    /// Any logged session in the window, of any type.
    private(set) var hasSessions = false
    /// Days since the most recent logged climb or lift (not just lifts with
    /// muscle groups; rest days do not count); nil when none in the window.
    private(set) var daysSinceLastWorkout: Int?
    private(set) var loaded = false

    private static let log = Logger(subsystem: "page.synced.app", category: "RecoveryStore")

    func state(for muscle: TrainedMuscle) -> RecoveryState {
        RecoveryState(daysSince: daysSince[muscle])
    }

    /// Most recent training across several muscles, for a map region or a
    /// group that covers more than one.
    func daysSince(anyOf muscles: [TrainedMuscle]) -> Int? {
        muscles.compactMap { daysSince[$0] }.min()
    }

    /// The most worked state among the muscles: one worked muscle makes the
    /// whole set read as worked.
    func state(forAnyOf muscles: [TrainedMuscle]) -> RecoveryState {
        RecoveryState(daysSince: daysSince(anyOf: muscles))
    }

    /// Groups counted as ready only when every muscle in them is ready, so a
    /// back with fresh traps but worked lats is not ready.
    var readyCount: Int {
        MuscleGroup.allCases.filter { group in
            TrainedMuscle.forParentGroup(group).allSatisfy { state(for: $0) == .ready }
        }.count
    }

    @MainActor
    func load() async {
        struct Row: Decodable {
            let session_type: String?
            let scheduled_date: String?
            let muscle_groups: [String]?
            let lift_exercises: LiftExerciseList?
        }
        let cal = WeekStore.calendar
        let today = cal.startOfDay(for: Date())
        guard let start = cal.date(byAdding: .day, value: -(Self.windowDays - 1), to: today) else { return }
        do {
            let userID = try await supabase.auth.session.user.id
            // Up to today only: a future-dated log has no recovery meaning yet.
            let rows: [Row] = try await supabase
                .from("sessions")
                .select("session_type, scheduled_date, muscle_groups, lift_exercises")
                .eq("user_id", value: userID.uuidString)
                .eq("is_planned", value: false)
                .gte("scheduled_date", value: WeekStore.dayFormatter.string(from: start))
                .lte("scheduled_date", value: WeekStore.dayFormatter.string(from: today))
                .execute()
                .value

            var result: [TrainedMuscle: Int] = [:]
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
                for muscle in Self.muscles(for: row.muscle_groups ?? [], exercises: row.lift_exercises?.items ?? []) {
                    result[muscle] = min(result[muscle] ?? days, days)
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

    /// Muscles one session trained, following the order in the type comment.
    static func muscles(for sessionGroups: [String], exercises: [LiftExercise]) -> Set<TrainedMuscle> {
        let fromSession = Set(MuscleGroup.expand(sessionGroups).flatMap(TrainedMuscle.forParentGroup))
        guard !exercises.isEmpty else { return fromSession }

        var out = Set<TrainedMuscle>()
        for exercise in exercises {
            if let entry = ExerciseCatalog.find(exercise.name) {
                out.formUnion(entry.allMuscles)
            } else if let tag = exercise.muscleGroup, !MuscleGroup.expand([tag]).isEmpty {
                out.formUnion(MuscleGroup.expand([tag]).flatMap(TrainedMuscle.forParentGroup))
            } else {
                out.formUnion(fromSession)
            }
        }
        return out
    }
}
