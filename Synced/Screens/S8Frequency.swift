import SwiftUI

struct S8Frequency: View {
    var model: OnboardingModel
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var phase = 0
    @State private var days: Double = 4

    var body: some View {
        ScreenShell(progress: ScreenProgress.s6, onBack: onBack, ambient: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("How often do you lift?")
                    .font(.synDisplay(28, weight: .bold))
                    .foregroundStyle(SYN.text)
                    .kerning(-0.9)
                    .lineSpacing(2)
                    .shadow(color: SYN.cyan.opacity(0.25), radius: 12)
                    .phaseFadeUp(phase: phase, delay: 0.18)

                Spacer().frame(height: 10)

                Text("Days per week, on average.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)
                    .phaseFadeUp(phase: phase, delay: 0.26)

                Spacer().frame(minHeight: 28)

                VStack(spacing: 8) {
                    Text("\(Int(days))")
                        .font(.synMono(120, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: SYN.cyan.opacity(0.55), radius: 30)
                        .shadow(color: SYN.cyan.opacity(0.35), radius: 80)
                    Text("Days per week")
                        .font(.synText(11, weight: .semibold))
                        .tracking(2.0)
                        .textCase(.uppercase)
                        .foregroundStyle(SYN.textFaint)
                }
                .frame(maxWidth: .infinity)
                .phaseFadeUp(phase: phase, delay: 0.30)

                Spacer().frame(minHeight: 32)

                SpecSlider(
                    value: $days,
                    range: 1...7,
                    step: 1,
                    ticks: [1, 2, 3, 4, 5, 6, 7],
                    tickLabels: ["1", "2", "3", "4", "5", "6", "7"]
                )
                .phaseFadeUp(phase: phase, delay: 0.42)

                Spacer().frame(minHeight: 16)
            }
        } cta: {
            PrimaryButton(title: "Continue") {
                let n = Int(days)
                model.daysPerWeek = n
                UserDefaults.standard.set(n, forKey: "trainingFrequency")
                onNext()
            }
        }
        .onAppear { days = Double(model.daysPerWeek) }
        .task { withAnimation { phase = 1 } }
    }
}
