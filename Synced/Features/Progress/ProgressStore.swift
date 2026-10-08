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
    var exerciseKey: String {
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
        let key = exerciseName.exerciseKey
        var recent: [SessionTopSet] = []
        // Newest first by date, not by fetch order.
        for session in sessions.sorted(by: { $0.date > $1.date }) where session.type == .lift {
            let tops = session.exercises
                .filter { $0.name.exerciseKey == key }
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

/// Top grade sent on one day.
struct GradePoint: Identifiable {
    let date: Date
    let grade: Int
    var id: Date { date }
}

struct ExercisePoint: Identifiable {
    let date: Date
    /// Heaviest set that session; drives the headline set.
    let set: LiftSet
    /// Final set that session; drives the session-over-session comparison.
    let lastSet: LiftSet
    var id: Date { date }
}

/// Last set of the latest session against the last set of the one before.
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

struct ExerciseTrend: Identifiable {
    let name: String
    /// Oldest first.
    let points: [ExercisePoint]
    var id: String { name.exerciseKey }
    var latest: ExercisePoint { points[points.count - 1] }
    var first: ExercisePoint { points[0] }
    var previous: ExercisePoint? { points.count >= 2 ? points[points.count - 2] : nil }

    /// nil until there are two sessions to compare.
    var sessionDelta: SessionDelta? {
        guard let previous else { return nil }
        return SessionDelta(
            weight: latest.lastSet.weightLbs - previous.lastSet.weightLbs,
            reps: latest.lastSet.reps - previous.lastSet.reps,
            bodyweight: latest.lastSet.isBodyweight && previous.lastSet.isBodyweight
        )
    }

    /// Latest session came in lighter or for fewer reps, with nothing better.
    var isDowntrend: Bool { sessionDelta?.tone == .down }
    var isUptrend: Bool { sessionDelta?.tone == .up }
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

/// Everything the Progress screen shows, derived from one fetch for a window.
struct ProgressSummary {
    let window: ProgressWindow

    // Climb
    let hasClimbs: Bool
    /// Any climb session at all, in or out of the window.
    let hasClimbedEver: Bool
    let topGrade: Int?
    let comparison: String?
    /// Oldest first, one point per day with climbing. Feeds the headline.
    let gradePoints: [GradePoint]
    /// Lift cards show the latest top set, rather than a before and after
    /// line, from this many sessions on.
    static let minChartPoints = 3
    /// Most recent point sits below an earlier peak.
    let climbDowntrend: Bool
    /// Grade and count, highest grade first.
    let sendCounts: [(grade: Int, count: Int)]

    // Lifts
    let hasLifts: Bool
    /// Exercises with two or more points; single-point exercises are omitted.
    let trends: [ExerciseTrend]

    /// One-line answer to "how am I doing"; nil when nothing was ever logged.
    let hero: ProgressHero?

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
        hasClimbedEver = sessions.contains { $0.type == .climb }
        let top = climbs.flatMap(\.grades).max()
        topGrade = top

        let prevStart = cal.date(byAdding: .day, value: -59, to: today) ?? today
        let prevTop = sessions
            .filter { $0.type == .climb && $0.date >= prevStart && $0.date < (windowStart ?? today) }
            .flatMap(\.grades)
            .max()

        if let top {
            switch window {
            case .last30:
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

        let byDay = Dictionary(grouping: climbs, by: { cal.startOfDay(for: $0.date) })
        gradePoints = byDay
            .compactMap { day, list in list.flatMap(\.grades).max().map { GradePoint(date: day, grade: $0) } }
            .sorted { $0.date < $1.date }

        let thisWeek = weekStart(today)

        if let last = gradePoints.last, gradePoints.count >= 2 {
            let earlierPeak = gradePoints.dropLast().map(\.grade).max() ?? last.grade
            climbDowntrend = last.grade < earlierPeak
        } else {
            climbDowntrend = false
        }

        sendCounts = Dictionary(grouping: climbs.flatMap(\.grades), by: { $0 })
            .map { (grade: $0.key, count: $0.value.count) }
            .sorted { $0.grade > $1.grade }

        // Lifts
        let lifts = inWindow.filter { $0.type == .lift }
        hasLifts = !lifts.isEmpty

        // Display casing is the first time the name was ever logged, across
        // all time, not just this window. Sessions arrive newest first (by
        // scheduled_date, then created_at), so walk them in reverse.
        var displayName: [String: String] = [:]
        for session in sessions.reversed() where session.type == .lift {
            for exercise in session.exercises where displayName[exercise.name.exerciseKey] == nil {
                displayName[exercise.name.exerciseKey] = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        var grouped: [String: (name: String, points: [ExercisePoint])] = [:]
        for session in lifts {
            for exercise in session.exercises {
                let key = exercise.name.exerciseKey
                guard !key.isEmpty, let set = exercise.topSet, let last = exercise.sets.last else { continue }
                var entry = grouped[key] ?? (name: displayName[key] ?? exercise.name, points: [])
                let point = ExercisePoint(date: session.date, set: set, lastSet: last)
                // One point per day: keep the session with the heavier top set.
                if let i = entry.points.firstIndex(where: { cal.isDate($0.date, inSameDayAs: session.date) }) {
                    if (set.weightLbs, set.reps) > (entry.points[i].set.weightLbs, entry.points[i].set.reps) {
                        entry.points[i] = point
                    }
                } else {
                    entry.points.append(point)
                }
                grouped[key] = entry
            }
        }
        let all = grouped.values
            .map { ExerciseTrend(name: $0.name, points: $0.points.sorted { $0.date < $1.date }) }
            .sorted { $0.latest.date > $1.latest.date }
        trends = all.filter { $0.points.count >= 2 }

        // Hero
        let climbDelta: Int?
        switch window {
        case .last30:
            climbDelta = top.flatMap { t in prevTop.map { t - $0 } }
        case .allTime:
            // No previous window: compare the latest climbing day with the
            // earlier peak, or with the first day when still climbing.
            if let last = gradePoints.last, let first = gradePoints.first, gradePoints.count >= 2 {
                let earlierPeak = gradePoints.dropLast().map(\.grade).max() ?? last.grade
                climbDelta = last.grade < earlierPeak ? last.grade - earlierPeak : (top ?? last.grade) - first.grade
            } else {
                climbDelta = nil
            }
        }
        hero = ProgressHero(
            everLogged: !sessions.isEmpty,
            sessionsInWindow: inWindow.count,
            window: window,
            topGrade: top,
            previousTop: prevTop,
            climbDelta: climbDelta,
            trends: trends
        )

        // Overall
        let monthStart = cal.dateInterval(of: .month, for: today)?.start ?? today
        sessionsThisMonth = sessions.filter { $0.date >= monthStart && $0.date <= now }.count
        let weekSessions = sessions.filter { $0.date >= thisWeek && $0.date <= now }
        sessionsThisWeek = weekSessions.count
        restDaysThisWeek = Set(weekSessions.filter { $0.type == .rest }.map { cal.startOfDay(for: $0.date) }).count
    }
}

/// The single headline at the top of Progress. Rules are checked in a fixed
/// order so exactly one applies: nothing logged (no hero), too little data,
/// a dip, moving forward, then holding steady. Dip is checked before moving
/// forward so a regression is never hidden behind a mixed picture.
struct ProgressHero {
    enum Tone { case early, forward, steady, dip }

    let tone: Tone
    let headline: String
    let support: String

    static let minSessions = 3

    init?(
        everLogged: Bool,
        sessionsInWindow: Int,
        window: ProgressWindow,
        topGrade: Int?,
        previousTop: Int?,
        climbDelta: Int?,
        trends: [ExerciseTrend]
    ) {
        guard everLogged else { return nil }

        guard sessionsInWindow >= Self.minSessions else {
            tone = .early
            headline = "Log a few more sessions."
            support = "Your progress picture fills in after \(Self.minSessions)+ sessions."
            return
        }

        let ups = trends.filter(\.isUptrend).count
        let downs = trends.filter(\.isDowntrend).count
        let count = trends.count
        let liftsDown = count > 0 && downs * 2 > count
        let liftsUp = count > 0 && ups * 2 >= count
        let delta = climbDelta ?? 0
        let monthly = window == .last30

        func lifts(_ n: Int) -> String { n == 1 ? "lift" : "lifts" }
        func grades(_ n: Int) -> String { n == 1 ? "grade" : "grades" }

        if delta < 0 || liftsDown {
            tone = .dip
            headline = "You're in a dip."
            var parts: [String] = []
            if delta < 0 {
                parts.append(monthly
                    ? "Top grade down \(-delta) from last month."
                    : "Latest top grade is \(-delta) below your peak.")
            }
            if downs > 0 {
                parts.append("\(downs) \(lifts(downs)) trending lighter.")
            }
            if liftsDown { parts.append("Might be time to deload.") }
            support = parts.joined(separator: " ")
        } else if delta > 0 || liftsUp {
            tone = .forward
            headline = "You're moving forward."
            var parts: [String] = []
            if delta > 0 { parts.append("+\(delta) climbing \(grades(delta))") }
            if ups > 0 { parts.append("\(ups) of \(count) tracked \(lifts(count)) improving") }
            support = parts.joined(separator: " and ") + "."
        } else {
            tone = .steady
            headline = "You're holding steady."
            var parts: [String] = []
            if let topGrade {
                if monthly, let previousTop, previousTop == topGrade {
                    parts.append("V\(topGrade) top for the second month")
                } else {
                    parts.append("V\(topGrade) top \(monthly ? "this month" : "so far")")
                }
            }
            if count > 0 {
                parts.append(ups == 0 && downs == 0
                    ? "\(count) tracked \(lifts(count)) unchanged"
                    : "\(ups) up and \(downs) down across \(count) tracked \(lifts(count))")
            }
            support = parts.isEmpty
                ? "Log climbs or track lift exercises to see which way you're heading."
                : parts.joined(separator: ", ") + "."
        }
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
