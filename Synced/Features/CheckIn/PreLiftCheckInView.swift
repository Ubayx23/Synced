import SwiftUI

struct PreLiftCheckInView: View {
    @Binding var isComplete: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: Int = 1
    @State private var sleepHours: Double = 7.5
    @State private var sleepQuality: Int = 0
    @State private var mealType: String = ""
    @State private var mealTime: Date = Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
    @State private var mealTiming: String = ""
    @State private var energyLevel: Double = 5.0

    @State private var ctaPulse: Double = 1.0

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
        .onChange(of: currentStep) { _, new in
            if new == 5 {
                ctaPulse = 0.96
                withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.05)) {
                    ctaPulse = 1.0
                }
            }
        }
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
                ForEach(1...5, id: \.self) { idx in
                    Circle()
                        .fill(idx <= currentStep ? SYN.cyan : SYN.border)
                        .frame(width: 6, height: 6)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: currentStep)

            Spacer()

            Text("\(currentStep) of 5")
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
                case 1: SleepHoursStep(value: $sleepHours)
                case 2: SleepQualityStep(value: $sleepQuality)
                case 3: MealTypeStep(value: $mealType)
                case 4: MealTimingStep(mealTime: $mealTime)
                default: EnergyLevelStep(value: $energyLevel)
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
        currentStep == 5 ? "Done, let's lift" : "Continue"
    }

    private var canAdvance: Bool {
        switch currentStep {
        case 1: return true
        case 2: return sleepQuality != 0
        case 3: return !mealType.trimmingCharacters(in: .whitespaces).isEmpty
        case 4: return mealTime <= Date()
        default: return true
        }
    }

    private var bottomCTA: some View {
        PrimaryButton(title: ctaLabel, action: advance)
            .opacity(canAdvance ? 1 : 0.5)
            .disabled(!canAdvance)
            .allowsHitTesting(canAdvance)
            .scaleEffect(currentStep == 5 ? ctaPulse : 1.0)
    }

    private func advance() {
        if currentStep == 4 {
            mealTiming = MealTimingStep.formatted(mealTime)
        }
        if currentStep == 5 {
            handleComplete()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { currentStep += 1 }
        }
    }

    private func handleComplete() {
        isComplete = true
        dismiss()
    }
}
