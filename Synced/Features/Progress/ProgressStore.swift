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
    /// only rewritten by an explicit rename (ProgressStore.renameExercise).
    var exerciseMatchKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

private extension AnyJSON {
    /// The match key of a raw lift_exercises entry; nil without a name.
    var exerciseMatchKey: String? {
        objectValue?["name"]?.stringValue?.exerciseMatchKey
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
    /// The day the account was created, for where the Consistency grid
    /// starts. Nil until loaded, or if the profile read fails.
    private(set) var accountCreated: Date?
    private(set) var loadState: LoadState = .loading

    /// Removes every entry matching `matchKey` from lift_exercises on all of
    /// the user's sessions, planned or logged. The sessions themselves stay.
    /// Other fields on each entry are written back untouched. Then unhides
    /// the key, since nothing is left to hide, and reloads.
    @MainActor
    func deleteExercise(matchKey: String) async throws {
        try await rewriteLiftExercises { list in
            list.filter { $0.exerciseMatchKey != matchKey }
        }
        try? await HiddenExercises.shared.unhide([matchKey])
        await load()
    }

    /// Writes `newName` on every entry matching `matchKey`, on all of the
    /// user's sessions. When the new name's key belongs to another exercise,
    /// the histories merge under it. The hidden state moves with the name.
    @MainActor
    func renameExercise(matchKey: String, to newName: String) async throws {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        try await rewriteLiftExercises { list in
            list.map { entry in
                guard entry.exerciseMatchKey == matchKey, var object = entry.objectValue else { return entry }
                object["name"] = .string(name)
                return .object(object)
            }
        }
        try? await HiddenExercises.shared.move(matchKey, to: name.exerciseMatchKey)
        await load()
    }

    /// Replaces one session's sets for `matchKey`, or removes the exercise
    /// from that session when `sets` is nil. Only that session's
    /// lift_exercises is written; the session row itself always stays. An
    /// exercise listed twice in the session is collapsed into its first
    /// entry, since Progress shows them as one.
    @MainActor
    func editExercise(matchKey: String, sessionID: UUID, sets: [LiftSet]?) async throws {
        let setsJSON: AnyJSON? = sets.map { sets in
            .array(sets.map { .object(["weight_lbs": .double($0.weightLbs), "reps": .integer($0.reps)]) })
        }
        try await rewriteLiftExercises(sessionID: sessionID) { list in
            var replaced = false
            return list.compactMap { entry in
                guard entry.exerciseMatchKey == matchKey else { return entry }
                guard let setsJSON, !replaced, var object = entry.objectValue else { return nil }
                replaced = true
                object["sets"] = setsJSON
                return .object(object)
            }
        }
        await load()
    }

    /// Reads lift_exercises on the user's sessions (or one session), passes
    /// each list through `transform`, and writes back only the rows that
    /// changed. Entries stay raw JSON, so fields this code doesn't know
    /// about are written back untouched.
    @MainActor
    private func rewriteLiftExercises(
        sessionID: UUID? = nil,
        _ transform: ([AnyJSON]) -> [AnyJSON]
    ) async throws {
        let userID = try await supabase.auth.session.user.id
        struct Row: Decodable {
            let id: UUID
            let lift_exercises: [AnyJSON]?
        }
        var query = supabase
            .from("sessions")
            .select("id, lift_exercises")
            .eq("user_id", value: userID.uuidString)
            .not("lift_exercises", operator: .is, value: "null")
        if let sessionID {
            query = query.eq("id", value: sessionID.uuidString)
        }
        let rows: [Row] = try await query.execute().value
        for row in rows {
            guard let list = row.lift_exercises else { continue }
            let next = transform(list)
            guard next != list else { continue }
            try await supabase
                .from("sessions")
                .update(["lift_exercises": AnyJSON.array(next)])
                .eq("id", value: row.id.uuidString)
                .eq("user_id", value: userID.uuidString)
                .execute()
        }
    }

    /// profiles.created_at as a local start of day. A failure here only
    /// moves the grid's start to the first session, so it is not an error.
    private static func accountCreated(userID: UUID) async -> Date? {
        struct Row: Decodable { let created_at: String }
        guard let row: Row = try? await supabase
            .from("profiles")
            .select("created_at")
            .eq("id", value: userID.uuidString)
            .single()
            .execute()
            .value
        else { return nil }
        // Postgres sends microseconds, which ISO8601DateFormatter rejects;
        // the day is all that matters, so drop the fraction.
        let trimmed = row.created_at.replacingOccurrences(of: #"\.\d+"#, with: "", options: .regularExpression)
        guard let date = ISO8601DateFormatter().date(from: trimmed) else { return nil }
        return WeekStore.calendar.startOfDay(for: date)
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
            accountCreated = await Self.accountCreated(userID: userID) ?? accountCreated
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

