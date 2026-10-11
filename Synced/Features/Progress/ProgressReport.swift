import Foundation

/// The 4W / 12W / ALL toggle on Progress.
enum ProgressScope: String, CaseIterable, Identifiable {
    case fourWeeks = "4W"
    case twelveWeeks = "12W"
    case all = "ALL"

    var id: String { rawValue }

    /// "Last 12 weeks", "All time": sheet subtitles and empty copy.
    var label: String {
        switch self {
        case .fourWeeks:   return "Last 4 weeks"
        case .twelveWeeks: return "Last 12 weeks"
        case .all:         return "All time"
        }
    }
}

/// One session's sets for one exercise.
struct ExerciseSessionSets: Identifiable {
    /// Session id.
    let id: UUID
    let date: Date
    let sets: [LiftSet]

    /// The set with the highest estimated 1RM; ties go to the heavier set.
    /// Bodyweight sets (0 lbs) compare by reps.
    var top: LiftSet? {
        sets.max { $0.score == $1.score ? $0.weightLbs < $1.weightLbs : $0.score < $1.score }
    }

    /// The top set, then the rest in logged order.
    var topFirst: [LiftSet] {
        guard let top, let index = sets.firstIndex(of: top) else { return sets }
        var rest = sets
        rest.remove(at: index)
        return [top] + rest
    }
}

/// Every logged session of one exercise, matched by `exerciseMatchKey`.
struct ExerciseHistory: Identifiable {
    /// Casing from the first time the exercise was logged.
    let name: String
    /// Newest first, across all time.
    let sessions: [ExerciseSessionSets]
    var id: String { name.exerciseMatchKey }

    var latest: ExerciseSessionSets? { sessions.first }

    /// Newest first, on or after `start`.
    func sessions(since start: Date) -> [ExerciseSessionSets] {
        sessions.filter { $0.date >= start }
    }
}

/// A lift whose latest top set in range has a higher estimated 1RM than its
/// first top set in range.
struct LiftImprovement: Identifiable {
    let history: ExerciseHistory
    let first: LiftSet
    let latest: LiftSet
    let latestDate: Date
    /// Top-set score for up to the last six sessions in range, oldest first.
    let spark: [Double]
    var id: String { history.id }

    /// For sorting: growth in estimated 1RM (reps for bodyweight).
    var size: Double { latest.score - first.score }
}

/// Latest top set against the previous session's, for the Lifts list.
enum LiftTrend {
    case up, down, flat, new
}

struct LiftRow: Identifiable {
    let history: ExerciseHistory
    let latest: LiftSet
    let trend: LiftTrend
    var id: String { history.id }
}

/// What a day in the Consistency grid shows. A logged climb wins over a
/// lift, a lift over rest.
enum DayMark {
    case climb, lift, rest
}

/// A first send above every earlier send: a dot on the grade line.
struct GradeBest: Identifiable {
    let grade: Int
    let date: Date
    /// Index into `ProgressReport.weeks`.
    let week: Int
    var id: Int { grade }
}

/// Everything the Progress screen shows, derived from one fetch. The hero
/// always compares calendar months; everything else follows the scope.
struct ProgressReport {
    let scope: ProgressScope
    let today: Date

    // Hero: this calendar month against last.
    let monthName: String
    let lastMonthName: String
    let topGradeThisMonth: Int?
    let topGradeLastMonth: Int?

    // Range: whole Monday-start weeks ending with this one.
    let weeks: [Date]
    var rangeStart: Date { weeks.first ?? today }

    // Grade line
    /// Max grade sent each week; nil for weeks with no climb with a send.
    let weeklyMax: [Int?]
    /// All time, so the dashed line means the same in every scope.
    let allTimeBest: Int?
    let bests: [GradeBest]
    var climbingWeeks: Int { weeklyMax.compactMap { $0 }.count }
    /// The line needs three climbing weeks in range.
    static let minimumClimbingWeeks = 3

    // Grade breakdown
    let sendCounts: [Int: Int]
    var totalSends: Int { sendCounts.values.reduce(0, +) }
    var topGrade: Int? { sendCounts.keys.max() }
    /// The grade with the most sends; ties go to the higher grade.
    var mostSent: Int? {
        sendCounts.max { $0.value == $1.value ? $0.key < $1.key : $0.value < $1.value }?.key
    }

    // Lifts
    let histories: [ExerciseHistory]
    /// Biggest improvement first.
    let improving: [LiftImprovement]
    /// Exercises logged in range, most recent first.
    let lifts: [LiftRow]
    /// Every logged lift session, all time.
    let totalLiftSessions: Int
    /// Exercises the user hid, alphabetical. Left out of Improving and Lifts.
    let hiddenHistories: [ExerciseHistory]

    // Consistency: from the user's start (or the range start, if later)
    // through today.
    /// First day the grid draws.
    let gridStart: Date
    /// Monday-start weeks from gridStart's week through this week.
    let gridWeeks: [Date]
    let dayMarks: [Date: DayMark]
    /// Logged climbs and lifts in the grid; rest days don't count.
    let sessionCount: Int
    /// No logged session at all yet.
    let hasNoSessions: Bool
    /// History is shorter than the range: "N sessions since Oct 8".
    let showsSince: Bool

    var perWeek: Double { gridWeeks.isEmpty ? 0 : Double(sessionCount) / Double(gridWeeks.count) }

    /// Whether a day is inside the grid: on or after gridStart, not after today.
    func isInGrid(_ day: Date) -> Bool {
        day >= gridStart && day <= today
    }

    init(sessions: [LoggedSession], scope: ProgressScope, accountCreated: Date? = nil, hidden: Set<String> = [], now: Date = Date()) {
        let cal = WeekStore.calendar
        let today = cal.startOfDay(for: now)
        self.scope = scope
        self.today = today
        let past = sessions.filter { $0.date <= today }.sorted { $0.date < $1.date }

        // Hero.
        let monthStart = cal.dateInterval(of: .month, for: today)?.start ?? today
        let lastMonthStart = cal.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
        monthName = monthStart.formatted(.dateTime.month(.wide))
        lastMonthName = lastMonthStart.formatted(.dateTime.month(.wide))
        let climbs = past.filter { $0.type == .climb }
        topGradeThisMonth = climbs.filter { $0.date >= monthStart }.flatMap(\.grades).max()
        topGradeLastMonth = climbs.filter { $0.date >= lastMonthStart && $0.date < monthStart }.flatMap(\.grades).max()

        // Range.
        let thisWeek = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let weekCount: Int = {
            switch scope {
            case .fourWeeks:   return 4
            case .twelveWeeks: return 12
            case .all:
                guard let first = past.first?.date,
                      let firstWeek = cal.dateInterval(of: .weekOfYear, for: first)?.start else { return 4 }
                let span = cal.dateComponents([.weekOfYear], from: firstWeek, to: thisWeek).weekOfYear ?? 0
                return max(4, span + 1)
            }
        }()
        let weeks = (0..<weekCount).reversed().compactMap { cal.date(byAdding: .weekOfYear, value: -$0, to: thisWeek) }
        self.weeks = weeks
        let start = weeks.first ?? thisWeek
        let inRange = past.filter { $0.date >= start }
        func weekIndex(_ date: Date) -> Int? {
            guard date >= start else { return nil }
            let days = cal.dateComponents([.day], from: start, to: cal.startOfDay(for: date)).day ?? 0
            let index = days / 7
            return index < weeks.count ? index : nil
        }

        // Grade line.
        var weekly = [Int?](repeating: nil, count: weeks.count)
        for climb in inRange where climb.type == .climb {
            guard let index = weekIndex(climb.date), let top = climb.grades.max() else { continue }
            weekly[index] = max(weekly[index] ?? top, top)
        }
        weeklyMax = weekly
        allTimeBest = climbs.flatMap(\.grades).max()
        var best: Int?
        var bestsByWeek: [Int: GradeBest] = [:]
        for climb in climbs {
            guard let top = climb.grades.max(), top > (best ?? -1) else { continue }
            best = top
            if let index = weekIndex(climb.date) {
                // One dot per week, at the week's highest new best.
                bestsByWeek[index] = GradeBest(grade: top, date: climb.date, week: index)
            }
        }
        bests = bestsByWeek.values.sorted { $0.week < $1.week }

        // Grade breakdown.
        sendCounts = Dictionary(grouping: inRange.filter { $0.type == .climb }.flatMap(\.grades), by: { $0 })
            .mapValues(\.count)

        // Lifts, grouped by exerciseMatchKey, newest session first.
        let liftSessions = past.filter { $0.type == .lift }
        totalLiftSessions = liftSessions.count
        var displayName: [String: String] = [:]
        for session in liftSessions {
            for exercise in session.exercises where displayName[exercise.name.exerciseMatchKey] == nil {
                displayName[exercise.name.exerciseMatchKey] = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        var order: [String] = []
        var grouped: [String: [ExerciseSessionSets]] = [:]
        for session in liftSessions.reversed() {
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
        self.histories = histories
        hiddenHistories = histories.filter { hidden.contains($0.id) }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let visible = histories.filter { !hidden.contains($0.id) }

        improving = visible
            .compactMap { history -> LiftImprovement? in
                let ranged = history.sessions(since: start)
                guard
                    ranged.count >= 2,
                    let latest = ranged.first, let latestTop = latest.top,
                    let firstTop = ranged.last?.top,
                    latestTop.score > firstTop.score
                else { return nil }
                let spark = ranged.prefix(6).reversed().compactMap(\.top?.score)
                return LiftImprovement(history: history, first: firstTop, latest: latestTop, latestDate: latest.date, spark: spark)
            }
            .sorted { $0.size > $1.size }

        lifts = visible.compactMap { history -> LiftRow? in
            guard let latest = history.latest, latest.date >= start, let top = latest.top else { return nil }
            let trend: LiftTrend
            if history.sessions.count < 2 {
                trend = .new
            } else if let previous = history.sessions[1].top {
                trend = top.score > previous.score ? .up : top.score < previous.score ? .down : .flat
            } else {
                trend = .flat
            }
            return LiftRow(history: history, latest: top, trend: trend)
        }

        // Consistency. The user started at the earlier of account creation
        // and their first logged session, so back-logged sessions count.
        let userStart = min(
            [accountCreated.map { cal.startOfDay(for: $0) }, past.first?.date].compactMap { $0 }.min() ?? today,
            today
        )
        let gridStart = scope == .all ? userStart : max(userStart, start)
        self.gridStart = gridStart
        let gridFirstWeek = cal.dateInterval(of: .weekOfYear, for: gridStart)?.start ?? gridStart
        let gridWeekCount = (cal.dateComponents([.weekOfYear], from: gridFirstWeek, to: thisWeek).weekOfYear ?? 0) + 1
        gridWeeks = (0..<max(1, gridWeekCount)).compactMap { cal.date(byAdding: .weekOfYear, value: $0, to: gridFirstWeek) }
        let inGrid = past.filter { $0.date >= gridStart }
        var marks: [Date: DayMark] = [:]
        for session in inGrid {
            let day = cal.startOfDay(for: session.date)
            switch (session.type, marks[day]) {
            case (.climb, _):           marks[day] = .climb
            case (.lift, .climb):       break
            case (.lift, _):            marks[day] = .lift
            case (.rest, nil):          marks[day] = .rest
            case (.rest, _):            break
            }
        }
        dayMarks = marks
        sessionCount = inGrid.filter { $0.type != .rest }.count
        hasNoSessions = past.isEmpty
        switch scope {
        case .all:
            // ALL has no fixed length; under four weeks reads as "since".
            let days = cal.dateComponents([.day], from: userStart, to: today).day ?? 0
            showsSince = days < 28
        case .fourWeeks, .twelveWeeks:
            showsSince = userStart > start
        }
    }
}

extension LiftSet {
    /// Estimated one-rep max (Epley): weight × (1 + reps / 30).
    var e1RM: Double { weightLbs * (1 + Double(reps) / 30) }

    /// How progress is judged everywhere: estimated 1RM, or reps for a
    /// bodyweight set.
    var score: Double { isBodyweight ? Double(reps) : e1RM }

    /// "185", "92.5", or "BW".
    var weightText: String {
        if isBodyweight { return "BW" }
        return weightLbs.rounded() == weightLbs
            ? String(Int(weightLbs))
            : weightLbs.formatted(.number.precision(.fractionLength(1)))
    }

    /// "185 × 5", or "BW × 10".
    var compact: String { "\(weightText) × \(reps)" }

    /// "185×5", for bar labels.
    var tight: String { "\(weightText)×\(reps)" }

    /// Change in score since `first`, rounded: lbs of estimated 1RM, or
    /// reps when both sets are bodyweight.
    func scoreChange(since first: LiftSet) -> Int {
        Int((score - first.score).rounded())
    }

    /// "+12 lbs est.", "-1 rep", or "No change".
    func scoreChangeText(since first: LiftSet) -> String {
        let delta = scoreChange(since: first)
        guard delta != 0 else { return "No change" }
        let sign = delta > 0 ? "+" : "-"
        if isBodyweight && first.isBodyweight {
            return "\(sign)\(abs(delta)) \(abs(delta) == 1 ? "rep" : "reps")"
        }
        return "\(sign)\(abs(delta)) lbs est."
    }

    /// "+10 lbs, -2 reps" when weight and reps moved opposite ways, so the
    /// trade behind the estimate is visible; nil otherwise.
    func tradeOff(since first: LiftSet) -> String? {
        let dw = weightLbs - first.weightLbs
        let dr = reps - first.reps
        guard (dw > 0 && dr < 0) || (dw < 0 && dr > 0) else { return nil }
        let amount = abs(dw).rounded() == abs(dw)
            ? String(Int(abs(dw)))
            : abs(dw).formatted(.number.precision(.fractionLength(1)))
        return "\(dw > 0 ? "+" : "-")\(amount) lbs, \(dr > 0 ? "+" : "-")\(abs(dr)) \(abs(dr) == 1 ? "rep" : "reps")"
    }
}

extension Date {
    /// "Oct 3".
    var shortDayLabel: String {
        formatted(.dateTime.month(.abbreviated).day())
    }
}
