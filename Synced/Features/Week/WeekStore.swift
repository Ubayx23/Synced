import Foundation
import Observation
import OSLog
import Supabase

enum SessionType: String, CaseIterable, Identifiable {
    case climb, lift, rest

    var id: String { rawValue }
}

/// Lift focus. A lift can have several, stored in muscle_groups in this
/// declaration order, which is also the picker's grid order.
enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest, back, shoulders, arms, legs
    case fullBody = "full_body"

    var id: String { rawValue }
}

/// One session is one pre_lift_checkins row. `isPlanned` is true until the
/// session is logged.
struct Session: Identifiable, Equatable {
    let id: UUID
    let type: SessionType
    let date: Date
    let isPlanned: Bool
    /// One entry per send, sorted ascending. [2, 2, 3] is two V2s and a V3.
    var grades: [Int] = []
    var muscles: [MuscleGroup] = []
    var exercises: [LiftExercise] = []
    var rating: Int? = nil
    var notes: String? = nil

    var topGrade: Int? { grades.max() }
}

/// One past use of an exercise: its name, the muscle groups it counts
/// for, and the sets logged that time.
struct ExerciseUse {
    let name: String
    /// The exercise's own muscle_group when saved with one. Older exercises
    /// without it fall back to every muscle group on their session.
    let muscles: Set<MuscleGroup>
    let sets: [LiftSet]
}

/// A past exercise offered as a chip on the Log sheet.
struct ExerciseSuggestion: Identifiable, Equatable {
    let name: String
    /// The selected muscle group this suggestion matched.
    let muscle: MuscleGroup?
    /// Sets from the most recent time it was logged, used to pre-fill.
    let sets: [LiftSet]
    var id: String { name.lowercased() }
}

/// Suggestion chips the user removed. Stored on this device per account;
/// logging the exercise again brings it back.
enum HiddenExerciseSuggestions {
    private static var key: String? {
        supabase.auth.currentSession.map { "hiddenExerciseSuggestions.\($0.user.id.uuidString)" }
    }

    static func load() -> Set<String> {
        guard let key else { return [] }
        return Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    static func hide(_ name: String) {
        guard let key else { return }
        var names = load()
        names.insert(name.lowercased())
        UserDefaults.standard.set(Array(names), forKey: key)
    }

    static func unhide(_ names: [String]) {
        guard let key, !names.isEmpty else { return }
        let current = load()
        let remaining = current.subtracting(names.map { $0.lowercased() })
        if remaining != current {
            UserDefaults.standard.set(Array(remaining), forKey: key)
        }
    }
}

/// What the Log session sheet saves. `id` is nil for a fresh log.
struct SessionLog {
    var id: UUID?
    var type: SessionType
    var date: Date
    var grades: [Int]
    var muscles: Set<MuscleGroup>
    /// Already cleaned: named exercises with at least one valid set.
    var exercises: [LiftExercise]
    var rating: Int?
    var notes: String
}

/// Loads, plans, and logs the sessions for one Monday to Sunday week.
@Observable
final class WeekStore {
    /// An empty week is `.loaded` with no sessions, never `.failed`.
    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    private(set) var sessions: [Session] = []
    private(set) var loadState: LoadState = .loading

    private static let log = Logger(subsystem: "page.synced.app", category: "WeekStore")

    /// Monday-first gregorian calendar so the week reads Mon to Sun in every locale.
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        cal.timeZone = .current
        return cal
    }()

    /// scheduled_date is a calendar day, so it round-trips as yyyy-MM-dd in
    /// the device time zone.
    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func weekDays(containing date: Date = Date()) -> [Date] {
        let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start
            ?? calendar.startOfDay(for: date)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    func sessions(on day: Date) -> [Session] {
        sessions.filter { Self.calendar.isDate($0.date, inSameDayAs: day) }
    }

    @MainActor
    func load(week days: [Date]) async {
        guard let first = days.first, let last = days.last else { return }
        do {
            let userID = try await supabase.auth.session.user.id
            let rows: [SessionRow] = try await supabase
                .from("pre_lift_checkins")
                .select(SessionRow.columns)
                .eq("user_id", value: userID.uuidString)
                .gte("scheduled_date", value: Self.dayFormatter.string(from: first))
                .lte("scheduled_date", value: Self.dayFormatter.string(from: last))
                .order("created_at", ascending: true)
                .execute()
                .value
            sessions = rows.compactMap(Self.session)
            loadState = .loaded
        } catch is CancellationError {
            // A refresh or view teardown interrupted the fetch; not a failure.
        } catch let error as URLError where error.code == .cancelled {
            // Same as above, surfaced by URLSession.
        } catch {
            Self.log.error("Week load failed: \(String(describing: error), privacy: .public)")
            loadState = .failed(error.localizedDescription)
        }
    }

    /// Inserts a planned session and appends it locally so it shows immediately.
    @MainActor
    func plan(_ type: SessionType, on day: Date) async throws {
        let userID = try await supabase.auth.session.user.id
        let payload = PlanInsert(
            user_id: userID.uuidString,
            session_type: type.rawValue,
            scheduled_date: Self.dayFormatter.string(from: day),
            is_planned: true
        )
        let row: SessionRow = try await supabase
            .from("pre_lift_checkins")
            .insert(payload)
            .select(SessionRow.columns)
            .single()
            .execute()
            .value
        if let session = Self.session(from: row) {
            sessions.append(session)
        }
    }

    /// Inserts a fresh log, or updates an existing planned or logged row.
    /// Either way the row ends up with is_planned = false.
    @MainActor
    func log(_ log: SessionLog) async throws {
        let userID = try await supabase.auth.session.user.id
        let fields = LogFields(log)
        let row: SessionRow
        if let id = log.id {
            row = try await supabase
                .from("pre_lift_checkins")
                .update(fields)
                .eq("id", value: id.uuidString)
                .select(SessionRow.columns)
                .single()
                .execute()
                .value
        } else {
            row = try await supabase
                .from("pre_lift_checkins")
                .insert(LogInsert(
                    user_id: userID.uuidString,
                    scheduled_date: Self.dayFormatter.string(from: log.date),
                    fields: fields
                ))
                .select(SessionRow.columns)
                .single()
                .execute()
                .value
        }
        guard let session = Self.session(from: row) else { return }
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }
    }

    /// Hard deletes the session's row and drops it locally. RLS already
    /// scopes deletes to the owner; the user_id filter is a second check.
    /// Supabase returns no error when RLS filters a delete out, so an empty
    /// result is treated as a failure rather than a silent success.
    @MainActor
    func delete(_ session: Session) async throws {
        struct DeletedRow: Decodable { let id: UUID }
        let userID = try await supabase.auth.session.user.id
        let deleted: [DeletedRow] = try await supabase
            .from("pre_lift_checkins")
            .delete()
            .eq("id", value: session.id.uuidString)
            .eq("user_id", value: userID.uuidString)
            .select("id")
            .execute()
            .value
        guard !deleted.isEmpty else { throw DeleteError.notDeleted }
        sessions.removeAll { $0.id == session.id }
    }

    enum DeleteError: LocalizedError {
        case notDeleted
        var errorDescription: String? {
            "The session wasn't removed. Check your connection and try again."
        }
    }

    /// Every exercise from the user's logged lifts, newest session first,
    /// tagged with its muscle group (or its session's groups for older
    /// exercises). Feeds the suggestion chips on the Log sheet; a failure
    /// just means no suggestions.
    static func exerciseHistory() async -> [ExerciseUse] {
        struct HistoryRow: Decodable {
            let muscle_groups: [String]?
            let lift_exercises: LiftExerciseList?
        }
        do {
            let userID = try await supabase.auth.session.user.id
            let rows: [HistoryRow] = try await supabase
                .from("pre_lift_checkins")
                .select("muscle_groups, lift_exercises")
                .eq("user_id", value: userID.uuidString)
                .eq("is_planned", value: false)
                .eq("session_type", value: SessionType.lift.rawValue)
                .order("scheduled_date", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value
            return rows.flatMap { row in
                let sessionMuscles = Set((row.muscle_groups ?? []).compactMap(MuscleGroup.init(rawValue:)))
                return (row.lift_exercises?.items ?? []).map { exercise in
                    let own = exercise.muscleGroup.flatMap(MuscleGroup.init(rawValue:))
                    return ExerciseUse(
                        name: exercise.name,
                        muscles: own.map { [$0] } ?? sessionMuscles,
                        sets: exercise.sets
                    )
                }
            }
        } catch {
            log.error("Exercise history failed: \(String(describing: error), privacy: .public)")
            return []
        }
    }

    private static func session(from row: SessionRow) -> Session? {
        guard
            let raw = row.session_type,
            let type = SessionType(rawValue: raw),
            let dateString = row.scheduled_date,
            let date = dayFormatter.date(from: String(dateString.prefix(10)))
        else { return nil }
        let notes = row.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        // Climbs logged before multi-grade only have climb_grade_v.
        let sent = row.climb_grades_sent ?? []
        let grades = sent.isEmpty ? (row.climb_grade_v.map { [$0] } ?? []) : sent
        let saved = Set((row.muscle_groups ?? []).compactMap(MuscleGroup.init(rawValue:)))
        return Session(
            id: row.id,
            type: type,
            date: date,
            isPlanned: row.is_planned ?? false,
            grades: grades.sorted(),
            muscles: MuscleGroup.allCases.filter(saved.contains),
            exercises: row.lift_exercises?.items ?? [],
            rating: row.rating,
            notes: notes?.isEmpty == false ? notes : nil
        )
    }
}

private struct SessionRow: Decodable {
    static let columns = "id, session_type, scheduled_date, is_planned, climb_grade_v, climb_grades_sent, muscle_groups, lift_exercises, rating, notes"

    let id: UUID
    let session_type: String?
    let scheduled_date: String?
    let is_planned: Bool?
    let climb_grade_v: Int?
    let climb_grades_sent: [Int]?
    let muscle_groups: [String]?
    let lift_exercises: LiftExerciseList?
    let rating: Int?
    let notes: String?
}

/// Decodes lift_exercises one element at a time so a malformed entry is
/// skipped instead of failing the whole row.
private struct LiftExerciseList: Decodable {
    let items: [LiftExercise]

    private struct Skip: Decodable {}

    init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        var items: [LiftExercise] = []
        while !c.isAtEnd {
            if let item = try? c.decode(LiftExercise.self) {
                items.append(item)
            } else {
                _ = try? c.decode(Skip.self)
            }
        }
        self.items = items
    }
}

extension LiftExercise: Encodable {
    init(name: String, sets: [LiftSet], muscleGroup: String? = nil) {
        self.name = name
        self.sets = sets
        self.muscleGroup = muscleGroup
    }

    private enum EncodingKeys: String, CodingKey { case name, muscle_group, sets }
    private enum SetKeys: String, CodingKey { case weight_lbs, reps }

    /// Writes the shape Progress reads, plus the optional muscle group:
    /// {"name": "Bench press", "muscle_group": "chest",
    ///  "sets": [{"weight_lbs": 185, "reps": 5}]}
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: EncodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(muscleGroup, forKey: .muscle_group)
        var list = c.nestedUnkeyedContainer(forKey: .sets)
        for set in sets {
            var item = list.nestedContainer(keyedBy: SetKeys.self)
            try item.encode(set.weightLbs, forKey: .weight_lbs)
            try item.encode(set.reps, forKey: .reps)
        }
    }
}

private struct PlanInsert: Encodable {
    let user_id: String
    let session_type: String
    let scheduled_date: String
    let is_planned: Bool
}

/// Columns a log writes. Fields that do not apply to the chosen type are
/// written as cleared values, so switching a session from climb to lift
/// does not leave stale grades behind. climb_grade_v mirrors the top send.
private struct LogFields: Encodable {
    let session_type: String
    let climb_grades_sent: [Int]?
    let climb_grade_v: Int?
    let muscle_groups: [String]
    let lift_exercises: [LiftExercise]?
    let rating: Int?
    let notes: String?

    init(_ log: SessionLog) {
        session_type = log.type.rawValue
        let sends = log.type == .climb ? log.grades.sorted() : []
        climb_grades_sent = sends.isEmpty ? nil : sends
        climb_grade_v = sends.max()
        muscle_groups = log.type == .lift
            ? MuscleGroup.allCases.filter(log.muscles.contains).map(\.rawValue)
            : []
        // null rather than [] when a lift has no exercises, or for other types.
        lift_exercises = log.type == .lift && !log.exercises.isEmpty ? log.exercises : nil
        rating = log.rating
        let trimmed = log.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        notes = trimmed.isEmpty ? nil : trimmed
    }

    private enum CodingKeys: String, CodingKey {
        case session_type, climb_grades_sent, climb_grade_v, muscle_groups, lift_exercises, rating, notes, is_planned
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(session_type, forKey: .session_type)
        try c.encode(climb_grades_sent, forKey: .climb_grades_sent)
        try c.encode(climb_grade_v, forKey: .climb_grade_v)
        try c.encode(muscle_groups, forKey: .muscle_groups)
        try c.encode(lift_exercises, forKey: .lift_exercises)
        try c.encode(rating, forKey: .rating)
        try c.encode(notes, forKey: .notes)
        try c.encode(false, forKey: .is_planned)
    }
}

private struct LogInsert: Encodable {
    let user_id: String
    let scheduled_date: String
    let fields: LogFields

    private enum CodingKeys: String, CodingKey {
        case user_id, scheduled_date
    }

    func encode(to encoder: Encoder) throws {
        try fields.encode(to: encoder)
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(user_id, forKey: .user_id)
        try c.encode(scheduled_date, forKey: .scheduled_date)
    }
}
