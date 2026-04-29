import SwiftUI

struct PreLiftCheckInView: View {
    @Binding var isComplete: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: Int = 1
    @State private var muscleGroups: [String] = []
    @State private var lastTrainedGap: String = ""
    @State private var sleepHours: Double = 7.5
    @State private var mealItems: [String] = []
    @State private var mealTime: Date = Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
    @State private var liftTime: Date = Date()
    @State private var hydration: String = ""
    @State private var preWorkout: String = ""

    @State private var ctaPulse: Double = 1.0
    @State private var draftLoaded: Bool = false

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
            saveDraft()
        }
        .onChange(of: muscleGroups)   { _, _ in saveDraft() }
        .onChange(of: lastTrainedGap) { _, _ in saveDraft() }
        .onChange(of: sleepHours)     { _, _ in saveDraft() }
        .onChange(of: mealItems)      { _, _ in saveDraft() }
        .onChange(of: mealTime)       { _, _ in saveDraft() }
        .onChange(of: liftTime)       { _, _ in saveDraft() }
        .onChange(of: hydration)      { _, _ in saveDraft() }
        .onChange(of: preWorkout)     { _, _ in saveDraft() }
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
                                    preWorkout: $preWorkout)
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
        currentStep == totalSteps ? "Done, let's lift" : "Continue"
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
        PrimaryButton(title: ctaLabel, action: advance)
            .opacity(canAdvance ? 1 : 0.5)
            .disabled(!canAdvance)
            .allowsHitTesting(canAdvance)
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
        PreLiftDraftStore.clear()
        isComplete = true
        dismiss()
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
        hydration      = draft.hydration
        preWorkout     = draft.preWorkout
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
                savedAt: Date()
            )
        )
    }
}

// MARK: - Draft model + storage

private struct PreLiftDraft: Codable {
    var currentStep: Int
    var muscleGroups: [String]
    var lastTrainedGap: String
    var sleepHours: Double
    var mealItems: [String]
    var mealTime: Date
    var liftTime: Date
    var hydration: String
    var preWorkout: String
    var savedAt: Date
}

private enum PreLiftDraftStore {
    // Bumped on each schema/flow change so older drafts are silently ignored.
    static let key = "preLiftDraft.v4"

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
