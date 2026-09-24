import Foundation
import Observation
import OSLog
import Supabase

/// One logged (not planned) session, reduced to what Progress needs.
struct LoggedSession: Identifiable, Equatable {
    let id: UUID
    let type: SessionType
    let date: Date
    /// One entry per send; empty for non-climb sessions.
    let grades: [Int]
    let exercises: [LiftExercise]
}

/// An exercise on a lift session, stored in pre_lift_checkins.lift_exercises
/// as `[{"name": "Bench press", "sets": [{"weight_lbs": 185, "reps": 5}]}]`.
struct LiftExercise: Decodable, Equatable {
    let name: String
    let sets: [LiftSet]

    /// Heaviest set, with more reps winning a tie.
    var topSet: LiftSet? {
        sets.max { ($0.weightLbs, $0.reps) < ($1.weightLbs, $1.reps) }
    }

    private enum CodingKeys: String, CodingKey { case name, sets }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        let raw = (try? c.decodeIfPresent([LenientSet].self, forKey: .sets)) ?? []
        sets = raw.compactMap(\.value)
    }
}

struct LiftSet: Equatable {
    let weightLbs: Double
    let reps: Int
}

/// Skips malformed sets instead of failing the whole row.
private struct LenientSet: Decodable {
    let value: LiftSet?

    private enum CodingKeys: String, CodingKey { case weight_lbs, reps }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let weight = try? c.decodeIfPresent(Double.self, forKey: .weight_lbs)
        let reps = try? c.decodeIfPresent(Int.self, forKey: .reps)
        if let weight, let reps, weight > 0, reps > 0 {
            value = LiftSet(weightLbs: weight, reps: reps)
        } else {
            value = nil
        }
    }
}

/// Fetches every logged session once; every Progress section aggregates
/// from this single result on the client.
@Observable
final class ProgressStore {
    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    private(set) var sessions: [LoggedSession] = []
    private(set) var loadState: LoadState = .loading

    private static let log = Logger(subsystem: "page.synced.app", category: "ProgressStore")

    @MainActor
    func load() async {
        do {
            let userID = try await supabase.auth.session.user.id
            // select * so a missing optional column (lift_exercises) reads
            // as absent instead of failing the fetch.
            let rows: [ProgressRow] = try await supabase
                .from("pre_lift_checkins")
                .select("*")
                .eq("user_id", value: userID.uuidString)
                .eq("is_planned", value: false)
                .order("scheduled_date", ascending: false)
                .execute()
                .value
            sessions = rows.compactMap(\.session)
            loadState = .loaded
        } catch is CancellationError {
            // Interrupted by a refresh or view teardown; not a failure.
        } catch let error as URLError where error.code == .cancelled {
            // Same as above, surfaced by URLSession.
        } catch {
            Self.log.error("Progress load failed: \(String(describing: error), privacy: .public)")
            loadState = .failed(error.localizedDescription)
        }
    }
}

private struct ProgressRow: Decodable {
    let session: LoggedSession?

    private enum CodingKeys: String, CodingKey {
        case id, session_type, scheduled_date, climb_grades_sent, climb_grade_v, lift_exercises
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard
            let id = try? c.decode(UUID.self, forKey: .id),
            let raw = try? c.decodeIfPresent(String.self, forKey: .session_type),
            let type = SessionType(rawValue: raw),
            let dateString = try? c.decodeIfPresent(String.self, forKey: .scheduled_date),
            let date = WeekStore.dayFormatter.date(from: String(dateString.prefix(10)))
        else {
            session = nil
            return
        }
        // Climbs logged before multi-grade only have climb_grade_v.
        let sent = (try? c.decodeIfPresent([Int].self, forKey: .climb_grades_sent)) ?? nil
        let single = (try? c.decodeIfPresent(Int.self, forKey: .climb_grade_v)) ?? nil
        let grades = type == .climb ? (sent?.isEmpty == false ? sent! : single.map { [$0] } ?? []) : []
        let exercises = type == .lift
            ? ((try? c.decodeIfPresent([LiftExercise].self, forKey: .lift_exercises)) ?? nil) ?? []
            : []
        session = LoggedSession(id: id, type: type, date: date, grades: grades, exercises: exercises)
    }
}

// MARK: - Aggregation

enum ProgressWindow: CaseIterable, Identifiable {
    case last30, allTime

    var id: Self { self }

    var title: String {
        switch self {
        case .last30:  return "Last 30 days"
        case .allTime: return "All time"
        }
    }
}

struct WeeklyGrade: Identifiable {
    let weekStart: Date
    let grade: Int
    var id: Date { weekStart }
}

struct ExercisePoint: Identifiable {
    let date: Date
    let set: LiftSet
    var id: Date { date }
}

struct ExerciseTrend: Identifiable {
    let name: String
    /// Oldest first.
    let points: [ExercisePoint]
    var id: String { name.lowercased() }
    var latest: ExercisePoint { points[points.count - 1] }
    var first: ExercisePoint { points[0] }
}

/// Everything the Progress screen shows, derived from one fetch for a window.
struct ProgressSummary {
    let window: ProgressWindow

    // Climb
    let hasClimbs: Bool
    let topGrade: Int?
    let comparison: String?
    let weeklyTop: [WeeklyGrade]
    let chartDomain: ClosedRange<Date>
    /// Grade and count, highest grade first.
    let sendCounts: [(grade: Int, count: Int)]

    // Lifts
    let hasLifts: Bool
    let trends: [ExerciseTrend]
    let firstLogs: [ExerciseTrend]

    // Overall (fixed periods, not the window)
    let sessionsThisMonth: Int
    let sessionsThisWeek: Int
    let restDaysThisWeek: Int

    init(sessions: [LoggedSession], window: ProgressWindow, now: Date = Date()) {
        let cal = WeekStore.calendar
        let today = cal.startOfDay(for: now)
        let windowStart: Date? = window == .last30
            ? cal.date(byAdding: .day, value: -29, to: today)
            : nil
        let inWindow = sessions.filter { s in windowStart.map { s.date >= $0 } ?? true }
        self.window = window

        func weekStart(_ date: Date) -> Date {
            cal.dateInterval(of: .weekOfYear, for: date)?.start ?? cal.startOfDay(for: date)
        }

        // Climb
        let climbs = inWindow.filter { $0.type == .climb && !$0.grades.isEmpty }
        hasClimbs = !climbs.isEmpty
        let top = climbs.flatMap(\.grades).max()
        topGrade = top

        if let top {
            switch window {
            case .last30:
                let prevStart = cal.date(byAdding: .day, value: -59, to: today) ?? today
                let prevTop = sessions
                    .filter { $0.type == .climb && $0.date >= prevStart && $0.date < (windowStart ?? today) }
                    .flatMap(\.grades)
                    .max()
                if let prevTop {
                    let delta = top - prevTop
                    if delta > 0 {
                        comparison = "+\(delta) \(delta == 1 ? "grade" : "grades") from last month"
                    } else if delta == 0 {
                        comparison = "Same as last month"
                    } else {
                        comparison = "\(delta) from last month"
                    }
                } else {
                    comparison = "No climbs logged the month before"
                }
            case .allTime:
                let firstSent = climbs.filter { $0.grades.contains(top) }.map(\.date).min()
                comparison = firstSent.map {
                    "First sent \($0.formatted(.dateTime.month(.abbreviated).day().year()))"
                }
            }
        } else {
            comparison = nil
        }

        let byWeek = Dictionary(grouping: climbs, by: { weekStart($0.date) })
        weeklyTop = byWeek
            .compactMap { week, list in list.flatMap(\.grades).max().map { WeeklyGrade(weekStart: week, grade: $0) } }
            .sorted { $0.weekStart < $1.weekStart }

        let thisWeek = weekStart(today)
        let domainStart: Date
        switch window {
        case .last30:
            domainStart = cal.date(byAdding: .weekOfYear, value: -7, to: thisWeek) ?? thisWeek
        case .allTime:
            domainStart = weeklyTop.first?.weekStart ?? thisWeek
        }
        chartDomain = min(domainStart, thisWeek)...thisWeek

        sendCounts = Dictionary(grouping: climbs.flatMap(\.grades), by: { $0 })
            .map { (grade: $0.key, count: $0.value.count) }
            .sorted { $0.grade > $1.grade }

        // Lifts
        let lifts = inWindow.filter { $0.type == .lift }
        hasLifts = !lifts.isEmpty

        var grouped: [String: (name: String, points: [ExercisePoint])] = [:]
        // Sessions arrive newest first, so the first name seen per key is the
        // most recent spelling.
        for session in lifts.sorted(by: { $0.date > $1.date }) {
            for exercise in session.exercises {
                let key = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !key.isEmpty, let set = exercise.topSet else { continue }
                var entry = grouped[key] ?? (name: exercise.name.trimmingCharacters(in: .whitespacesAndNewlines), points: [])
                // One point per day: keep the heavier top set.
                if let i = entry.points.firstIndex(where: { cal.isDate($0.date, inSameDayAs: session.date) }) {
                    if (set.weightLbs, set.reps) > (entry.points[i].set.weightLbs, entry.points[i].set.reps) {
                        entry.points[i] = ExercisePoint(date: session.date, set: set)
                    }
                } else {
                    entry.points.append(ExercisePoint(date: session.date, set: set))
                }
                grouped[key] = entry
            }
        }
        let all = grouped.values
            .map { ExerciseTrend(name: $0.name, points: $0.points.sorted { $0.date < $1.date }) }
            .sorted { $0.latest.date > $1.latest.date }
        trends = all.filter { $0.points.count >= 2 }
        firstLogs = all.filter { $0.points.count == 1 }

        // Overall
        let monthStart = cal.dateInterval(of: .month, for: today)?.start ?? today
        sessionsThisMonth = sessions.filter { $0.date >= monthStart && $0.date <= now }.count
        let weekSessions = sessions.filter { $0.date >= thisWeek && $0.date <= now }
        sessionsThisWeek = weekSessions.count
        restDaysThisWeek = Set(weekSessions.filter { $0.type == .rest }.map { cal.startOfDay(for: $0.date) }).count
    }
}

extension LiftSet {
    /// "195 lbs × 5", dropping a trailing ".0".
    var formatted: String {
        let weight = weightLbs.rounded() == weightLbs
            ? String(Int(weightLbs))
            : weightLbs.formatted(.number.precision(.fractionLength(1)))
        return "\(weight) lbs × \(reps)"
    }
}
