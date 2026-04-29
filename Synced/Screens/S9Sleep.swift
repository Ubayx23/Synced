import SwiftUI

struct S9Sleep: View {
    var model: OnboardingModel
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var phase = 0
    @State private var hours: Double = 7.5

    private var whole: Int { Int(hours) }
    private var halfText: String {
        let frac = hours - Double(whole)
        return frac >= 0.25 ? ".5" : ""
    }

    var body: some View {
        ScreenShell(progress: ScreenProgress.s7, onBack: onBack) {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowTag(text: "Recovery input")
                    .phaseFadeUp(phase: phase, delay: 0.05)

                Spacer().frame(height: 18)

                (Text("How much do you usually ")
                    .foregroundColor(.white)
                 + Text("sleep")
                    .foregroundColor(SYN.cyan)
                 + Text("?").foregroundColor(.white))
                    .font(.synDisplay(28, weight: .bold))
                    .kerning(-0.9)
                    .lineSpacing(2)
                    .shadow(color: SYN.cyan.opacity(0.25), radius: 12)
                    .phaseFadeUp(phase: phase, delay: 0.18)

                Spacer().frame(height: 10)

                Text("Hours per night, your typical average. We'll compare against your actual check-ins.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)
                    .phaseFadeUp(phase: phase, delay: 0.26)

                Spacer().frame(minHeight: 28)

                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text("\(whole)")
                        .font(.synMono(120, weight: .bold))
                        .foregroundStyle(.white)
                    Text(halfText)
                        .font(.synMono(80, weight: .bold))
                        .foregroundStyle(.white)
                    Text("h")
                        .font(.synMono(40, weight: .medium))
                        .foregroundStyle(SYN.textFaint)
                        .padding(.leading, 6)
                }
                .frame(maxWidth: .infinity)
                .shadow(color: SYN.cyan.opacity(0.55), radius: 30)
                .shadow(color: SYN.cyan.opacity(0.35), radius: 80)
                .phaseFadeUp(phase: phase, delay: 0.30)

                Spacer().frame(minHeight: 28)

                SpecSlider(
                    value: $hours,
                    range: 4...12,
                    step: 0.5,
                    ticks: [4, 6, 8, 10, 12],
                    tickLabels: ["4h", "6h", "8h", "10h", "12h"]
                )
                .phaseFadeUp(phase: phase, delay: 0.42)

                Spacer().frame(minHeight: 16)
            }
        } cta: {
            PrimaryButton(title: "Continue") {
                model.sleepHours = hours
                UserDefaults.standard.set(hours, forKey: "sleepBaseline")
                onNext()
            }
        }
        .onAppear { hours = model.sleepHours }
        .task { withAnimation { phase = 1 } }
    }
}
