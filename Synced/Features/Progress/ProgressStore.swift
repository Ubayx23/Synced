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

extension String {
    /// Canonical key for matching exercise names: trimmed and lowercased, so
    /// "Curls", "CURLS", and "curls " are one exercise. Stored names are
    /// never rewritten; this only affects grouping, matching, and suggestions.
    var exerciseMatchKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

/// An exercise on a lift session, stored in sessions.lift_exercises
/// as `[{"name": "Bench press", "muscle_group": "chest",
/// "sets": [{"weight_lbs": 185, "reps": 5}]}]`. muscle_group is optional;
/// exercises saved before it existed omit it.
struct LiftExercise: Decodable, Equatable {
    let name: String
    let sets: [LiftSet]
    /// The one muscle group this exercise was logged for, as a raw value.
    let muscleGroup: String?

    /// Heaviest set, with more reps winning a tie.
    var topSet: LiftSet? {
        sets.max { ($0.weightLbs, $0.reps) < ($1.weightLbs, $1.reps) }
    }

    private enum CodingKeys: String, CodingKey { case name, sets, muscle_group }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        muscleGroup = (try? c.decodeIfPresent(String.self, forKey: .muscle_group)) ?? nil
        let raw = (try? c.decodeIfPresent([LenientSet].self, forKey: .sets)) ?? []
        sets = raw.compactMap(\.value)
    }
}

struct LiftSet: Equatable {
    let weightLbs: Double
    let reps: Int

    /// Logged at 0 lbs: pull-ups, dips, hangs, and the like.
    var isBodyweight: Bool { weightLbs == 0 }
}

/// Skips malformed sets instead of failing the whole row.
private struct LenientSet: Decodable {
    let value: LiftSet?

    private enum CodingKeys: String, CodingKey { case weight_lbs, reps }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let weight = try? c.decodeIfPresent(Double.self, forKey: .weight_lbs)
        let reps = try? c.decodeIfPresent(Int.self, forKey: .reps)
        // 0 lbs is a bodyweight set, not a missing value.
        if let weight, let reps, weight >= 0, reps > 0 {
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

    /// The last `limit` sessions that logged this exercise with at least one
    /// valid set, oldest to newest, each with its heaviest set. Matches names
    /// the same way the trend grouping does. Reads the already-fetched
    /// sessions only; no network call.
    func recentTopSets(for exerciseName: String, limit: Int = 7) -> [SessionTopSet] {
        let key = exerciseName.exerciseMatchKey
        var recent: [SessionTopSet] = []
        // Newest first by date, not by fetch order.
        for session in sessions.sorted(by: { $0.date > $1.date }) where session.type == .lift {
            let tops = session.exercises
                .filter { $0.name.exerciseMatchKey == key }
                .compactMap(\.topSet)
            guard let top = tops.max(by: { ($0.weightLbs, $0.reps) < ($1.weightLbs, $1.reps) }) else { continue }
            recent.append(SessionTopSet(id: session.id, date: session.date, top: top))
            if recent.count == limit { break }
        }
        return recent.reversed()
    }

    private static let log = Logger(subsystem: "page.synced.app", category: "ProgressStore")

    @MainActor
    func load() async {
        do {
            let userID = try await supabase.auth.session.user.id
            let rows: [ProgressRow] = try await supabase
                .from("sessions")
                .select("id, session_type, scheduled_date, climb_grades_sent, climb_grade_v, lift_exercises")
                .eq("user_id", value: userID.uuidString)
                .eq("is_planned", value: false)
                .order("scheduled_date", ascending: false)
                .order("created_at", ascending: false)
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
        // Element by element, like WeekStore: one malformed exercise is
        // skipped instead of dropping the session's whole list.
        let exercises = type == .lift
            ? ((try? c.decodeIfPresent(LiftExerciseList.self, forKey: .lift_exercises)) ?? nil)?.items ?? []
            : []
        session = LoggedSession(id: id, type: type, date: date, grades: grades, exercises: exercises)
    }
}

// MARK: - Aggregation

/// Change between two sets of the same exercise.
struct SessionDelta {
    enum Tone { case up, down, mixed, same }

    let weight: Double
    let reps: Int
    /// Both sessions' last sets were bodyweight: compare by reps only.
    var bodyweight = false

    var tone: Tone {
        if weight == 0 && reps == 0 { return .same }
        if weight >= 0 && reps >= 0 { return .up }
        if weight <= 0 && reps <= 0 { return .down }
        return .mixed
    }

    /// "+10 lbs, same reps", "Same weight, +2 reps", "+5 lbs, -1 rep", or
    /// "+2 reps, bodyweight" when both sessions were bodyweight.
    var text: String {
        if tone == .same { return "Same as last session" }
        let repWord = abs(reps) == 1 ? "rep" : "reps"
        if bodyweight {
            return "\(reps > 0 ? "+" : "-")\(abs(reps)) \(repWord), bodyweight"
        }
        let amount = abs(weight).rounded() == abs(weight)
            ? String(Int(abs(weight)))
            : abs(weight).formatted(.number.precision(.fractionLength(1)))
        let weightPart = weight > 0 ? "+\(amount) lbs" : weight < 0 ? "-\(amount) lbs" : "Same weight"
        let repsPart = reps > 0 ? "+\(reps) \(repWord)" : reps < 0 ? "-\(-reps) \(repWord)" : "same reps"
        return "\(weightPart), \(repsPart)"
    }
}

/// One session's heaviest set for an exercise, for the mini bar chart.
struct SessionTopSet: Identifiable {
    /// Session id.
    let id: UUID
    let date: Date
    let top: LiftSet
}

extension Array where Element == SessionTopSet {
    /// Bar values: top-set weight, or reps when every set is bodyweight,
    /// since bodyweight bars would all be zero.
    var chartValues: [Double] {
        allSatisfy(\.top.isBodyweight)
            ? map { Double($0.top.reps) }
            : map(\.top.weightLbs)
    }
}

/// First send at a grade, for the milestone list under the pyramid.
struct GradeMilestone: Identifiable {
    let grade: Int
    let date: Date
    var id: Int { grade }
}

/// One session's sets for one exercise, for the history view.
struct ExerciseSessionSets: Identifiable {
    /// Session id.
    let id: UUID
    let date: Date
    let sets: [LiftSet]

    /// The set with the most weight times reps; ties go to the heavier set.
    /// Bodyweight sets (0 lbs) compare by reps.
    var top: LiftSet? {
        sets.max { $0.effort == $1.effort ? $0.weightLbs < $1.weightLbs : $0.effort < $1.effort }
    }
}

/// Every logged session of one exercise, matched by `exerciseMatchKey`.
struct ExerciseHistory: Identifiable {
    /// Casing from the first time the exercise was logged.
    let name: String
    /// Newest first.
    let sessions: [ExerciseSessionSets]
    var id: String { name.exerciseMatchKey }

    var latest: ExerciseSessionSets? { sessions.first }
    var previous: ExerciseSessionSets? { sessions.count >= 2 ? sessions[1] : nil }
}

/// An exercise whose latest top set beat the previous session's.
struct ExerciseImprovement: Identifiable {
    let history: ExerciseHistory
    let previous: LiftSet
    let current: LiftSet
    var id: String { history.id }

    var delta: SessionDelta {
        SessionDelta(
            weight: current.weightLbs - previous.weightLbs,
            reps: current.reps - previous.reps,
            bodyweight: current.isBodyweight && previous.isBodyweight
        )
    }

    /// For sorting: growth in weight times reps, bodyweight counted as 1 lb.
    var size: Double { current.effort - previous.effort }
}

/// Everything the Progress screen shows, derived from one fetch.
struct ProgressReport {
    // Climbing
    let topGradeThisMonth: Int?
    let topGradeLastMonth: Int?
    let hasClimbedEver: Bool
    /// Grade and count across all time, highest grade first.
    let sendCounts: [(grade: Int, count: Int)]
    /// Newest first, at most five.
    let milestones: [GradeMilestone]

    // Lifts
    /// Biggest improvement first.
    let improving: [ExerciseImprovement]
    /// Most recently logged first.
    let recentLifts: [ExerciseHistory]

    init(sessions: [LoggedSession], now: Date = Date()) {
        let cal = WeekStore.calendar
        let today = cal.startOfDay(for: now)
        let past = sessions.filter { $0.date <= today }

        // Climbing: calendar months.
        let monthStart = cal.dateInterval(of: .month, for: today)?.start ?? today
        let lastMonthStart = cal.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
        let climbs = past.filter { $0.type == .climb }
        hasClimbedEver = !climbs.isEmpty
        topGradeThisMonth = climbs.filter { $0.date >= monthStart }.flatMap(\.grades).max()
        topGradeLastMonth = climbs.filter { $0.date >= lastMonthStart && $0.date < monthStart }.flatMap(\.grades).max()
        sendCounts = Dictionary(grouping: climbs.flatMap(\.grades), by: { $0 })
            .map { (grade: $0.key, count: $0.value.count) }
            .sorted { $0.grade > $1.grade }

        var firstSent: [Int: Date] = [:]
        for climb in climbs {
            for grade in climb.grades where firstSent[grade].map({ climb.date < $0 }) ?? true {
                firstSent[grade] = climb.date
            }
        }
        milestones = firstSent
            .map { GradeMilestone(grade: $0.key, date: $0.value) }
            .sorted { $0.date == $1.date ? $0.grade > $1.grade : $0.date > $1.date }
            .prefix(5)
            .map { $0 }

        // Lifts, grouped by exerciseMatchKey. Sessions arrive newest first.
        let lifts = past.filter { $0.type == .lift }
        var displayName: [String: String] = [:]
        for session in lifts.reversed() {
            for exercise in session.exercises where displayName[exercise.name.exerciseMatchKey] == nil {
                displayName[exercise.name.exerciseMatchKey] = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        var order: [String] = []
        var grouped: [String: [ExerciseSessionSets]] = [:]
        for session in lifts {
            // An exercise listed twice in one session counts as one entry.
            var bySession: [String: [LiftSet]] = [:]
            var sessionOrder: [String] = []
            for exercise in session.exercises where !exercise.sets.isEmpty {
                let key = exercise.name.exerciseMatchKey
                guard !key.isEmpty else { continue }
                if bySession[key] == nil { sessionOrder.append(key) }
                bySession[key, default: []] += exercise.sets
            }
            for key in sessionOrder {
                if grouped[key] == nil { order.append(key) }
                grouped[key, default: []].append(
                    ExerciseSessionSets(id: session.id, date: session.date, sets: bySession[key] ?? [])
                )
            }
        }
        let histories = order.map { key in
            ExerciseHistory(name: displayName[key] ?? key, sessions: grouped[key] ?? [])
        }
        recentLifts = histories

        improving = histories
            .compactMap { history -> ExerciseImprovement? in
                guard
                    let current = history.latest?.top,
                    let previous = history.previous?.top,
                    current.isImprovement(over: previous)
                else { return nil }
                return ExerciseImprovement(history: history, previous: previous, current: current)
            }
            .sorted { $0.size > $1.size }
    }
}

extension LiftSet {
    /// Weight times reps, with bodyweight counted as 1 lb so reps still count.
    var effort: Double { (isBodyweight ? 1 : weightLbs) * Double(reps) }

    /// More weight at the same or more reps, or more reps at the same or
    /// more weight. Flat or traded-off sets are not improvements.
    func isImprovement(over previous: LiftSet) -> Bool {
        (weightLbs > previous.weightLbs && reps >= previous.reps)
            || (reps > previous.reps && weightLbs >= previous.weightLbs)
    }

    /// "185 × 5", or "BW × 10", for compact set lists.
    var compact: String {
        if isBodyweight { return "BW × \(reps)" }
        let weight = weightLbs.rounded() == weightLbs
            ? String(Int(weightLbs))
            : weightLbs.formatted(.number.precision(.fractionLength(1)))
        return "\(weight) × \(reps)"
    }
}

extension LiftSet {
    /// "195 lbs × 5", dropping a trailing ".0", or "BW × 10".
    var formatted: String {
        if isBodyweight { return "BW × \(reps)" }
        let weight = weightLbs.rounded() == weightLbs
            ? String(Int(weightLbs))
            : weightLbs.formatted(.number.precision(.fractionLength(1)))
        return "\(weight) lbs × \(reps)"
    }
}
