import SwiftUI
import Charts
import Supabase

private struct SessionDot: Identifiable {
    let id = UUID()
    let date: Date
    let rating: Double
}

private struct SleepRow: Decodable { let sleep_hours: Double? }
private struct RatingRow: Decodable { let session_rating: Int? }
private struct GapRow: Decodable { let meal_time: Date?; let lift_time: Date? }
private struct ChartRow: Decodable {
    let session_rating: Int?
    let created_at: Date
}
private struct LockCountRow: Decodable { let id: String }

private struct PreLiftFullRow: Decodable {
    let id: String
    let created_at: Date
    let muscle_groups: [String]?
    let last_trained_gap: String?
    let sleep_hours: Double?
    let meal_items: [FoodItem]?
    let meal_time: Date?
    let lift_time: Date?
    let hydration: String?
    let pre_workout: String?
    let pre_workout_brand: String?
    let pre_workout_caffeine_mg: Int?
}

private struct PostLiftFullRow: Decodable {
    let pre_lift_id: String?
    let session_rating: Int?
    let performance_vs_expectation: String?
    let session_duration: String?
    let notes: String?
}

private struct Paired {
    let rating: Double
    let session: SessionRecord
}

struct StatsView: View {
    @State private var avgSleep: Double? = nil
    @State private var avgRating: Double? = nil
    @State private var avgGap: Double? = nil
    @State private var sessionDots: [SessionDot] = []
    @State private var preLiftCount: Int? = nil
    @State private var sessions: [SessionRecord] = []
    @State private var selectedSession: SessionRecord? = nil
    @State private var insights: [InsightCard] = []

    private var isUnlocked: Bool {
        if let count = preLiftCount { return count >= 7 }
        return false
    }

    var body: some View {
        if isUnlocked {
            unlockedBody
        } else {
            lockedBody
        }
    }

    private var unlockedBody: some View {
        ZStack {
            SYN.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 16)

                    Spacer().frame(height: 24)

                    insightsFeed

                    Spacer().frame(height: 32)

                    EyebrowText(text: "Session history")
                        .foregroundStyle(SYN.textFaint)

                    Spacer().frame(height: 8)

                    Text("Last 30 days")
                        .font(.synText(13))
                        .foregroundStyle(SYN.textFaint)

                    Spacer().frame(height: 16)

                    chart

                    Spacer().frame(height: 24)

                    EyebrowText(text: "Your averages")
                        .foregroundStyle(SYN.textFaint)

                    Spacer().frame(height: 16)

                    averagesRow

                    Spacer().frame(height: 32)

                    EyebrowText(text: "Recent sessions")
                        .foregroundStyle(SYN.textFaint)

                    Spacer().frame(height: 12)

                    LazyVStack(spacing: 8) {
                        ForEach(Array(sessions.prefix(10))) { session in
                            SessionRow(session: session) {
                                selectedSession = session
                            }
                        }
                    }

                    Color.clear.frame(height: 32)
                }
                .padding(.horizontal, Spacing.pageH)
            }
        }
        .sheet(item: $selectedSession) { record in
            SessionDetailView(session: record)
                .presentationDetents([.large])
        }
        .task {
            async let a: () = loadAverages()
            async let c: () = loadChart()
            async let l: () = loadLockState()
            async let s: () = loadSessions()
            _ = await (a, c, l, s)
        }
    }

    // MARK: - Locked body

    private var lockedBody: some View {
        ZStack {
            SYN.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(SYN.cyan)

                Spacer().frame(height: 24)

                Text("Your Insights")
                    .font(.synDisplay(28, weight: .bold))
                    .foregroundStyle(SYN.text)

                Spacer().frame(height: 8)

                EyebrowText(text: "Locked")
                    .foregroundStyle(SYN.textFaint)

                Spacer().frame(height: 24)

                Text("\(preLiftCount ?? 0) of 7 check-ins logged")
                    .font(.synMono(15))
                    .foregroundStyle(SYN.text)

                Spacer().frame(height: 12)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(SYN.border)
                        RoundedRectangle(cornerRadius: 2).fill(SYN.cyan)
                            .frame(width: geo.size.width *
                                min(1, max(0, Double(preLiftCount ?? 0) / 7.0)))
                    }
                }
                .frame(width: 240, height: 4)

                Spacer().frame(height: 24)

                Text("Keep showing up. Each check-in gets you closer.")
                    .font(.synText(14))
                    .foregroundStyle(SYN.textDim)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)

                Spacer()
            }
            .padding(.horizontal, Spacing.pageH)
        }
        .task { await loadLockState() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Insights")
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)
            Text("Based on 15 sessions")
                .font(.synText(14))
                .foregroundStyle(SYN.textDim)
        }
    }

    // MARK: - Insights

    @ViewBuilder
    private var insightsFeed: some View {
        if insights.isEmpty {
            Text("Insights are forming. Keep checking in.")
                .font(.synText(14))
                .foregroundStyle(SYN.textFaint)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: Radius.card)
                        .fill(SYN.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card)
                        .stroke(SYN.border, lineWidth: 1)
                )
        } else {
            VStack(spacing: 12) {
                ForEach(insights) { card in
                    InsightCardView(card: card)
                }
            }
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Group {
            if sessionDots.isEmpty {
                Text("No sessions yet")
                    .font(.synText(13))
                    .foregroundStyle(SYN.textFaint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(sessionDots) { dot in
                    LineMark(
                        x: .value("Date", dot.date),
                        y: .value("Rating", dot.rating)
                    )
                    .foregroundStyle(SYN.cyan.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", dot.date),
                        y: .value("Rating", dot.rating)
                    )
                    .foregroundStyle(colorForRating(dot.rating))
                    .symbolSize(120)
                }
                .chartYScale(domain: 1...5)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                        AxisGridLine()
                            .foregroundStyle(SYN.border)
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text("\(v)")
                                    .font(.system(size: 11))
                                    .foregroundColor(SYN.textFaint)
                            }
                        }
                    }
                }
            }
        }
        .frame(height: 180)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(SYN.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SYN.border, lineWidth: 1)
        )
    }

    private func colorForRating(_ rating: Double) -> Color {
        switch rating {
        case 5: return SYN.cyan
        case 4: return SYN.green
        case 3: return SYN.text
        case 2: return SYN.amber
        default: return SYN.red
        }
    }

    // MARK: - Averages

    private var averagesRow: some View {
        HStack(spacing: 12) {
            AveragePill(
                value: avgSleep.map { String(format: "%.1f", $0) } ?? "--",
                valueColor: SYN.text,
                label: "avg sleep"
            )
            AveragePill(
                value: avgRating.map { String(format: "%.1f", $0) } ?? "--",
                valueColor: SYN.cyan,
                label: "avg rating"
            )
            AveragePill(
                value: avgGap.map { String(format: "%.1fh", $0) } ?? "--",
                valueColor: SYN.text,
                label: "avg gap"
            )
        }
    }

    // MARK: - Supabase

    private func loadAverages() async {
        guard let userID = supabase.auth.currentSession?.user.id else { return }
        let userIDString = userID.uuidString

        async let sleepTask: [SleepRow] = supabase
            .from("pre_lift_checkins")
            .select("sleep_hours")
            .eq("user_id", value: userIDString)
            .execute()
            .value

        async let ratingTask: [RatingRow] = supabase
            .from("post_lift_checkins")
            .select("session_rating")
            .eq("user_id", value: userIDString)
            .execute()
            .value

        async let gapTask: [GapRow] = supabase
            .from("pre_lift_checkins")
            .select("meal_time, lift_time")
            .eq("user_id", value: userIDString)
            .execute()
            .value

        let sleepRows = try? await sleepTask
        let ratingRows = try? await ratingTask
        let gapRows = try? await gapTask

        let newAvgSleep: Double? = {
            guard let rows = sleepRows else { return nil }
            let values = rows.compactMap { $0.sleep_hours }
            guard !values.isEmpty else { return nil }
            return values.reduce(0, +) / Double(values.count)
        }()

        let newAvgRating: Double? = {
            guard let rows = ratingRows else { return nil }
            let values = rows.compactMap { $0.session_rating }
            guard !values.isEmpty else { return nil }
            return Double(values.reduce(0, +)) / Double(values.count)
        }()

        let newAvgGap: Double? = {
            guard let rows = gapRows else { return nil }
            let hours: [Double] = rows.compactMap { row in
                guard let meal = row.meal_time,
                      let lift = row.lift_time,
                      lift > meal else { return nil }
                return lift.timeIntervalSince(meal) / 3600
            }
            guard !hours.isEmpty else { return nil }
            return hours.reduce(0, +) / Double(hours.count)
        }()

        await MainActor.run {
            if let newAvgSleep  { avgSleep  = newAvgSleep }
            if let newAvgRating { avgRating = newAvgRating }
            if let newAvgGap    { avgGap    = newAvgGap }
        }
    }

    private func loadLockState() async {
        guard let userID = supabase.auth.currentSession?.user.id else { return }

        do {
            let rows: [LockCountRow] = try await supabase
                .from("pre_lift_checkins")
                .select("id")
                .eq("user_id", value: userID.uuidString)
                .execute()
                .value
            let count = rows.count
            await MainActor.run { preLiftCount = count }
        } catch {
            // swallow silently; locked view stays
        }
    }

    // MARK: - Insights

    private func computeInsights(from sessions: [SessionRecord]) -> [InsightCard] {
        let paired: [Paired] = sessions.compactMap { s in
            guard let r = s.sessionRating else { return nil }
            return Paired(rating: Double(r), session: s)
        }
        guard paired.count >= 3 else { return [] }

        func avg(_ xs: [Double]) -> Double {
            xs.isEmpty ? 0 : xs.reduce(0, +) / Double(xs.count)
        }
        func fmt(_ x: Double) -> String { String(format: "%.1f", x) }

        var cards: [InsightCard] = []

        // a) Sleep
        let hiSleep = paired.filter { ($0.session.sleepHours ?? -1) >= 7.5 }
        let loSleep = paired.filter {
            guard let s = $0.session.sleepHours else { return false }
            return s < 7.5
        }
        if hiSleep.count >= 2 && loSleep.count >= 2 {
            let hiAvg = avg(hiSleep.map { $0.rating })
            let loAvg = avg(loSleep.map { $0.rating })
            if hiAvg - loAvg >= 0.5 {
                cards.append(InsightCard(
                    headline: "You lift best after 7.5+ hours of sleep",
                    supportingStat: "Avg rating \(fmt(hiAvg)) with 7.5h+ vs \(fmt(loAvg)) with less",
                    sessionCount: hiSleep.count + loSleep.count,
                    sentiment: .positive,
                    icon: "moon.stars.fill"
                ))
            }
        }

        // b) Meal gap
        struct GapEntry { let gap: Double; let rating: Double }
        let gaps: [GapEntry] = paired.compactMap { p in
            guard let meal = p.session.mealTime,
                  let lift = p.session.liftTime,
                  lift > meal else { return nil }
            return GapEntry(gap: lift.timeIntervalSince(meal) / 3600, rating: p.rating)
        }
        let sweet = gaps.filter { (2.0...3.0).contains($0.gap) }
        let others = gaps.filter { !(2.0...3.0).contains($0.gap) }
        if sweet.count >= 2 && others.count >= 2 {
            let sweetAvg = avg(sweet.map { $0.rating })
            let otherAvg = avg(others.map { $0.rating })
            if sweetAvg - otherAvg >= 0.5 {
                cards.append(InsightCard(
                    headline: "Sweet spot is lifting 2 to 3 hours after eating",
                    supportingStat: "Avg rating \(fmt(sweetAvg)) in this window vs \(fmt(otherAvg)) outside",
                    sessionCount: sweet.count + others.count,
                    sentiment: .positive,
                    icon: "clock.fill"
                ))
            }
        }

        // c & d) Best/worst meal
        var mealRatings: [String: [Double]] = [:]
        for p in paired {
            var seen: Set<String> = []
            for item in p.session.mealItems {
                let key = item.name.lowercased()
                if seen.contains(key) { continue }
                seen.insert(key)
                mealRatings[key, default: []].append(p.rating)
            }
        }
        let mealStats = mealRatings
            .filter { $0.value.count >= 2 }
            .map { (name: $0.key, count: $0.value.count, mean: avg($0.value)) }

        if let best = mealStats.max(by: { $0.mean < $1.mean }), best.mean >= 4.0 {
            cards.append(InsightCard(
                headline: "\(best.name.capitalized) before lifting is your best meal",
                supportingStat: "Avg rating \(fmt(best.mean)) on sessions with this meal",
                sessionCount: best.count,
                sentiment: .positive,
                icon: "fork.knife"
            ))
        }
        if let worst = mealStats.min(by: { $0.mean < $1.mean }), worst.mean <= 3.0 {
            cards.append(InsightCard(
                headline: "\(worst.name.capitalized) before lifting hurts your sessions",
                supportingStat: "Avg rating \(fmt(worst.mean)) on sessions with this meal",
                sessionCount: worst.count,
                sentiment: .negative,
                icon: "exclamationmark.triangle.fill"
            ))
        }

        // e) Pre-workout effect
        let withPW = paired.filter { $0.session.preWorkout == "Pre-workout" }
        let withoutPW = paired.filter { $0.session.preWorkout == "None" }
        if withPW.count >= 2 && withoutPW.count >= 2 {
            let withAvg = avg(withPW.map { $0.rating })
            let withoutAvg = avg(withoutPW.map { $0.rating })
            if abs(withAvg - withoutAvg) >= 0.5 {
                let headline: String
                let sentiment: InsightSentiment
                let icon: String
                if withAvg > withoutAvg {
                    headline  = "Pre-workout boosts your sessions"
                    sentiment = .positive
                    icon      = "bolt.fill"
                } else {
                    headline  = "Pre-workout does not improve your sessions"
                    sentiment = .warning
                    icon      = "bolt.slash.fill"
                }
                cards.append(InsightCard(
                    headline: headline,
                    supportingStat: "Avg rating \(fmt(withAvg)) with vs \(fmt(withoutAvg)) without pre-workout",
                    sessionCount: withPW.count + withoutPW.count,
                    sentiment: sentiment,
                    icon: icon
                ))
            }
        }

        // f) Best day of week
        let calendar = Calendar.current
        let dayNames = [1: "Sunday", 2: "Monday", 3: "Tuesday", 4: "Wednesday",
                        5: "Thursday", 6: "Friday", 7: "Saturday"]
        var byDay: [Int: [Double]] = [:]
        for p in paired {
            let dow = calendar.component(.weekday, from: p.session.createdAt)
            byDay[dow, default: []].append(p.rating)
        }
        for (day, ratings) in byDay where ratings.count >= 2 {
            let thisAvg = avg(ratings)
            let otherRatings = paired
                .filter { calendar.component(.weekday, from: $0.session.createdAt) != day }
                .map { $0.rating }
            guard !otherRatings.isEmpty else { continue }
            let otherAvg = avg(otherRatings)
            if thisAvg - otherAvg >= 0.8, let name = dayNames[day] {
                cards.append(InsightCard(
                    headline: "Your \(name) sessions are strongest",
                    supportingStat: "Avg rating \(fmt(thisAvg)) on this day vs \(fmt(otherAvg)) on others",
                    sessionCount: paired.count,
                    sentiment: .positive,
                    icon: "calendar.badge.checkmark"
                ))
            }
        }

        return Array(cards.sorted { $0.sessionCount > $1.sessionCount }.prefix(5))
    }

    private func loadSessions() async {
        guard let userID = supabase.auth.currentSession?.user.id else { return }

        do {
            let preRows: [PreLiftFullRow] = try await supabase
                .from("pre_lift_checkins")
                .select("*")
                .eq("user_id", value: userID.uuidString)
                .order("created_at", ascending: false)
                .limit(100)
                .execute()
                .value

            let preIds = preRows.map { $0.id }

            var postByPre: [String: PostLiftFullRow] = [:]
            if !preIds.isEmpty {
                let postRows: [PostLiftFullRow] = try await supabase
                    .from("post_lift_checkins")
                    .select("*")
                    .in("pre_lift_id", values: preIds)
                    .execute()
                    .value
                for row in postRows {
                    guard let key = row.pre_lift_id else { continue }
                    postByPre[key] = row
                }
            }

            let records: [SessionRecord] = preRows.map { pre in
                let post = postByPre[pre.id]
                return SessionRecord(
                    id: pre.id,
                    createdAt: pre.created_at,
                    muscleGroups: pre.muscle_groups ?? [],
                    lastTrainedGap: pre.last_trained_gap,
                    sleepHours: pre.sleep_hours,
                    mealItems: pre.meal_items ?? [],
                    mealTime: pre.meal_time,
                    liftTime: pre.lift_time,
                    hydration: pre.hydration,
                    preWorkout: pre.pre_workout,
                    preWorkoutBrand: pre.pre_workout_brand,
                    preWorkoutCaffeineMg: pre.pre_workout_caffeine_mg,
                    sessionRating: post?.session_rating,
                    performanceVsExpectation: post?.performance_vs_expectation,
                    sessionDuration: post?.session_duration,
                    notes: post?.notes
                )
            }

            let newInsights = computeInsights(from: records)
            await MainActor.run {
                sessions = records
                insights = newInsights
            }
        } catch {
            // swallow silently
        }
    }

    private func loadChart() async {
        guard let userID = supabase.auth.currentSession?.user.id else { return }
        let monthAgo = ISO8601DateFormatter().string(
            from: Date().addingTimeInterval(-30 * 24 * 3600)
        )

        do {
            let rows: [ChartRow] = try await supabase
                .from("post_lift_checkins")
                .select("session_rating, created_at")
                .eq("user_id", value: userID.uuidString)
                .gte("created_at", value: monthAgo)
                .order("created_at", ascending: true)
                .execute()
                .value

            let dots = rows.compactMap { row -> SessionDot? in
                guard let rating = row.session_rating else { return nil }
                return SessionDot(date: row.created_at, rating: Double(rating))
            }

            await MainActor.run {
                sessionDots = dots
            }
        } catch {
            // swallow silently
        }
    }
}

private struct AveragePill: View {
    let value: String
    let valueColor: Color
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.synMono(20, weight: .bold))
                .foregroundStyle(valueColor)
            Text(label)
                .font(.synText(11))
                .foregroundStyle(SYN.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SYN.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SYN.border, lineWidth: 1)
        )
    }
}

private struct SessionRow: View {
    let session: SessionRecord
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 8, height: 8)

                Spacer().frame(width: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.createdAt, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                        .font(.synText(15, weight: .semibold))
                        .foregroundStyle(SYN.text)

                    if let rating = session.sessionRating {
                        Text("Rated \(rating)/5")
                            .font(.synText(12))
                            .foregroundStyle(SYN.textDim)
                    } else {
                        Text("No rating")
                            .font(.synText(12))
                            .foregroundStyle(SYN.textFaint)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SYN.textFaint)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(SYN.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(SYN.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var dotColor: Color {
        guard let rating = session.sessionRating else { return SYN.textFaint }
        switch Double(rating) {
        case 5: return SYN.cyan
        case 4: return SYN.green
        case 3: return SYN.text
        case 2: return SYN.amber
        default: return SYN.red
        }
    }
}

#Preview {
    StatsView()
        .preferredColorScheme(.dark)
}
