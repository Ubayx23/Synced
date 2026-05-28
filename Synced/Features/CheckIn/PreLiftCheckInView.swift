import SwiftUI
import Supabase

struct PreLiftCheckInView: View {
    @Binding var isComplete: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: Int = 1
    @State private var muscleGroups: [String] = []
    @State private var lastTrainedGap: String = ""
    @State private var sleepHours: Double = 7.5
    @State private var mealItems: [FoodItem] = []
    @State private var mealTime: Date = Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
    @State private var liftTime: Date = Date()
    @State private var hydration: String = ""
    @State private var preWorkout: String = ""
    @State private var preWorkoutBrand: String = ""
    @State private var preWorkoutCaffeineMg: Int = 0

    @State private var ctaPulse: Double = 1.0
    @State private var draftLoaded: Bool = false

    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    private let totalSteps = 4

    var body: some View {
        ZStack {
            SYN.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, Spacing.pageH)
                    .padding(.top, 16)

                Spacer().frame(height: 24)

                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.synText(13))
                        .foregroundStyle(SYN.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, Spacing.pageH)
                        .padding(.bottom, 12)
                }

                bottomCTA
                    .padding(.horizontal, Spacing.pageH)
                    .padding(.bottom, 48)
            }
        }
        .onAppear { restoreDraftIfFresh() }
        .onChange(of: currentStep) { _, new in
            if new == totalSteps {
                ctaPulse = 0.96
                withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.05)) {
                    ctaPulse = 1.0
                }
            }
        }
        .onChange(of: draftSnapshot) { _, _ in saveDraft() }
    }

    /// Single hash representing the entire saveable state. Combining all
    /// observed fields into one `.onChange` keeps the body type-checker fast
    /// (the long chain of nine onChanges previously timed out the compiler).
    private var draftSnapshot: Int {
        var hasher = Hasher()
        hasher.combine(currentStep)
        hasher.combine(muscleGroups)
        hasher.combine(lastTrainedGap)
        hasher.combine(sleepHours)
        hasher.combine(mealItems)
        hasher.combine(mealTime)
        hasher.combine(liftTime)
        hasher.combine(hydration)
        hasher.combine(preWorkout)
        hasher.combine(preWorkoutBrand)
        hasher.combine(preWorkoutCaffeineMg)
        return hasher.finalize()
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .center) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SYN.textFaint)
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 8) {
                ForEach(1...totalSteps, id: \.self) { idx in
                    Circle()
                        .fill(idx <= currentStep ? SYN.cyan : SYN.border)
                        .frame(width: 6, height: 6)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: currentStep)

            Spacer()

            Text("\(currentStep) of \(totalSteps)")
                .font(.synText(13))
                .foregroundStyle(SYN.textDim)
                .frame(width: 44, alignment: .trailing)
        }
    }

    // MARK: - Step content

    @ViewBuilder
    private var stepContent: some View {
        ZStack {
            Group {
                switch currentStep {
                case 1: RecoveryStep(muscleGroups: $muscleGroups, lastTrainedGap: $lastTrainedGap)
                case 2: SleepStep(sleepHours: $sleepHours)
                case 3: FoodStep(mealItems: $mealItems)
                default: TimingStep(mealTime: $mealTime,
                                    liftTime: $liftTime,
                                    hydration: $hydration,
                                    preWorkout: $preWorkout,
                                    preWorkoutBrand: $preWorkoutBrand,
                                    preWorkoutCaffeineMg: $preWorkoutCaffeineMg)
                }
            }
            .id(currentStep)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .animation(.easeInOut(duration: 0.25), value: currentStep)
    }

    // MARK: - CTA

    private var ctaLabel: String {
        if currentStep == totalSteps && isSubmitting { return "Saving..." }
        return currentStep == totalSteps ? "Done, let's lift" : "Continue"
    }

    private var canAdvance: Bool {
        switch currentStep {
        case 1: return !muscleGroups.isEmpty && !lastTrainedGap.isEmpty
        case 2: return true
        case 3: return !mealItems.isEmpty
        default: return liftTime > mealTime && !hydration.isEmpty && !preWorkout.isEmpty
        }
    }

    private var bottomCTA: some View {
        let enabled = canAdvance && !isSubmitting
        return PrimaryButton(title: ctaLabel, action: advance)
            .opacity(enabled ? 1 : 0.5)
            .disabled(!enabled)
            .allowsHitTesting(enabled)
            .scaleEffect(currentStep == totalSteps ? ctaPulse : 1.0)
    }

    private func advance() {
        if currentStep == totalSteps {
            handleComplete()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { currentStep += 1 }
        }
    }

    private func handleComplete() {
        errorMessage = nil
        isSubmitting = true

        guard let userID = supabase.auth.currentSession?.user.id else {
            errorMessage = "Your session expired. Please sign in again."
            isSubmitting = false
            return
        }

        let trimmedBrand = preWorkoutBrand.trimmingCharacters(in: .whitespacesAndNewlines)
        let brandField: String? = trimmedBrand.isEmpty ? nil : trimmedBrand
        let caffeineField: Int? = preWorkoutCaffeineMg == 0 ? nil : preWorkoutCaffeineMg

        let payload = PreLiftCheckInPayload(
            user_id: userID.uuidString,
            muscle_groups: muscleGroups,
            last_trained_gap: lastTrainedGap,
            sleep_hours: sleepHours,
            meal_items: mealItems,
            meal_time: mealTime,
            lift_time: liftTime,
            hydration: hydration,
            pre_workout: preWorkout,
            pre_workout_brand: brandField,
            pre_workout_caffeine_mg: caffeineField,
            input_score: computeInputScore()
        )

        Task {
            do {
                try await supabase
                    .from("pre_lift_checkins")
                    .insert(payload)
                    .execute()

                await rollupProfile(userID: userID)

                await MainActor.run {
                    PreLiftDraftStore.clear()
                    isComplete = true
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }

    // MARK: - Scoring

    private func sleepScore() -> Int {
        switch sleepHours {
        case ..<6:   return 20
        case 6..<7:  return 40
        case 7..<8:  return 70
        case 8...9:  return 100
        default:     return 80
        }
    }

    private func mealTimingScore() -> Int {
        let hours = liftTime.timeIntervalSince(mealTime) / 3600
        switch hours {
        case ..<1:   return 20
        case 1..<2:  return 50
        case 2...3:  return 100
        case 3...4:  return 80
        default:     return 60
        }
    }

    private func hydrationScore() -> Int {
        switch hydration {
        case "High":   return 100
        case "Normal": return 70
        case "Low":    return 30
        default:       return 30
        }
    }

    private func preWorkoutScore() -> Int {
        switch preWorkout {
        case "Pre-workout": return 90
        case "Coffee":      return 85
        case "None":        return 70
        default:            return 70
        }
    }

    private func computeInputScore() -> Int {
        let weighted = 0.35 * Double(sleepScore())
                     + 0.35 * Double(mealTimingScore())
                     + 0.15 * Double(hydrationScore())
                     + 0.15 * Double(preWorkoutScore())
        return Int(weighted.rounded())
    }

    // MARK: - Profile rollup

    private func rollupProfile(userID: UUID) async {
        do {
            struct CountRow: Decodable { let id: String }
            let weekAgo = ISO8601DateFormatter().string(
                from: Date().addingTimeInterval(-7 * 24 * 3600)
            )

            let preRows: [CountRow] = try await supabase
                .from("pre_lift_checkins")
                .select("id")
                .eq("user_id", value: userID.uuidString)
                .gte("created_at", value: weekAgo)
                .execute()
                .value
            let postRows: [CountRow] = try await supabase
                .from("post_lift_checkins")
                .select("id")
                .eq("user_id", value: userID.uuidString)
                .gte("created_at", value: weekAgo)
                .execute()
                .value

            let weeklyScore = min(100, 40 + 5 * preRows.count + 5 * postRows.count)

            let tier = Tier.allCases.first { $0.range.contains(weeklyScore) } ?? .active
            let tierName = tier.displayName

            let monthAgo = ISO8601DateFormatter().string(
                from: Date().addingTimeInterval(-30 * 24 * 3600)
            )
            let dateRows: [DateRow] = try await supabase
                .from("pre_lift_checkins")
                .select("created_at")
                .eq("user_id", value: userID.uuidString)
                .gte("created_at", value: monthAgo)
                .order("created_at", ascending: false)
                .execute()
                .value

            let calendar = Calendar.current
            let days = Set(dateRows.map { calendar.startOfDay(for: $0.created_at) })
            let today = calendar.startOfDay(for: Date())
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return }

            var streak = 0
            if days.contains(today) || days.contains(yesterday) {
                var cursor = days.contains(today) ? today : yesterday
                while days.contains(cursor) {
                    streak += 1
                    guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
                    cursor = prev
                }
            }

            try await supabase
                .from("profiles")
                .update(ProfileRollup(score: weeklyScore, tier: tierName, streak: streak))
                .eq("id", value: userID.uuidString)
                .execute()

            struct LeaderboardUpsert: Encodable {
                let user_id: String
                let display_name: String
                let tier: String
                let score: Int
                let streak: Int
            }
            let stored = UserDefaults.standard.string(forKey: "userName")?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let displayName = stored.isEmpty ? "User" : stored

            try await supabase
                .from("leaderboard_entries")
                .upsert(
                    LeaderboardUpsert(
                        user_id: userID.uuidString,
                        display_name: displayName,
                        tier: tierName,
                        score: weeklyScore,
                        streak: streak
                    ),
                    onConflict: "user_id"
                )
                .execute()
        } catch {
            // Rollup is best-effort. The check-in row is already saved.
        }
    }

    // MARK: - Draft persistence

    private func restoreDraftIfFresh() {
        defer { draftLoaded = true }
        guard let draft = PreLiftDraftStore.load() else { return }
        guard Calendar.current.isDate(draft.savedAt, inSameDayAs: Date()) else {
            PreLiftDraftStore.clear()
            return
        }
        currentStep    = min(max(draft.currentStep, 1), totalSteps)
        muscleGroups   = draft.muscleGroups
        lastTrainedGap = draft.lastTrainedGap
        sleepHours     = draft.sleepHours
        mealItems      = draft.mealItems
        mealTime       = draft.mealTime
        liftTime       = draft.liftTime
        hydration              = draft.hydration
        preWorkout             = draft.preWorkout
        preWorkoutBrand        = draft.preWorkoutBrand
        preWorkoutCaffeineMg   = draft.preWorkoutCaffeineMg
    }

    private func saveDraft() {
        guard draftLoaded else { return }
        PreLiftDraftStore.save(
            PreLiftDraft(
                currentStep: currentStep,
                muscleGroups: muscleGroups,
                lastTrainedGap: lastTrainedGap,
                sleepHours: sleepHours,
                mealItems: mealItems,
                mealTime: mealTime,
                liftTime: liftTime,
                hydration: hydration,
                preWorkout: preWorkout,
                preWorkoutBrand: preWorkoutBrand,
                preWorkoutCaffeineMg: preWorkoutCaffeineMg,
                savedAt: Date()
            )
        )
    }
}

// MARK: - Insert payload

private struct PreLiftCheckInPayload: Encodable {
    let user_id: String
    let muscle_groups: [String]
    let last_trained_gap: String
    let sleep_hours: Double
    let meal_items: [FoodItem]
    let meal_time: Date
    let lift_time: Date
    let hydration: String
    let pre_workout: String
    let pre_workout_brand: String?
    let pre_workout_caffeine_mg: Int?
    let input_score: Int
}

private struct DateRow: Decodable {
    let created_at: Date
}

private struct ProfileRollup: Encodable {
    let score: Int
    let tier: String
    let streak: Int
}

// MARK: - Draft model + storage

private struct PreLiftDraft: Codable {
    var currentStep: Int
    var muscleGroups: [String]
    var lastTrainedGap: String
    var sleepHours: Double
    var mealItems: [FoodItem]
    var mealTime: Date
    var liftTime: Date
    var hydration: String
    var preWorkout: String
    var preWorkoutBrand: String
    var preWorkoutCaffeineMg: Int
    var savedAt: Date
}

private enum PreLiftDraftStore {
    // Bumped on each schema/flow change so older drafts are silently ignored.
    static let key = "preLiftDraft.v7"

    /// Drafts written by an older schema fail to decode; we treat that as
    /// "no draft" and let the user start fresh.
    static func load() -> PreLiftDraft? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PreLiftDraft.self, from: data)
    }

    static func save(_ draft: PreLiftDraft) {
        guard let data = try? JSONEncoder().encode(draft) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
