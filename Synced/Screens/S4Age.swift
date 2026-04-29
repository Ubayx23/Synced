import SwiftUI

struct S4Age: View {
    var model: OnboardingModel
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var phase = 0
    @State private var age: Int = 20

    var body: some View {
        ScreenShell(progress: ScreenProgress.s4, onBack: onBack) {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowTag(text: "Baseline calibration")
                    .phaseFadeUp(phase: phase, delay: 0.05)

                Spacer().frame(height: 16)

                ageHeadline
                    .font(.synDisplay(30, weight: .bold))
                    .kerning(-0.9)
                    .shadow(color: SYN.cyan.opacity(0.25), radius: 12)
                    .phaseFadeUp(phase: phase, delay: 0.18)

                Spacer().frame(height: 10)

                Text("Helps calibrate your recovery baseline.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)
                    .phaseFadeUp(phase: phase, delay: 0.30)

                Spacer().frame(minHeight: 32)

                AgePicker(value: $age)
                    .frame(maxWidth: .infinity)
                    .phaseFadeUp(phase: phase, delay: 0.40)

                Spacer().frame(minHeight: 12)
            }
        } cta: {
            PrimaryButton(title: "Continue") {
                model.age = age
                UserDefaults.standard.set(age, forKey: "userAge")
                onNext()
            }
        }
        .onAppear { age = model.age }
        .task { withAnimation { phase = 1 } }
    }

    /// Headline tail varies on whether we have the user's first name yet.
    private var ageHeadline: Text {
        let suffix = model.firstName.isEmpty ? "?" : ", \(model.firstName)?"
        return Text("How old ").foregroundColor(.white)
            + Text("are you").foregroundColor(SYN.cyan)
            + Text(suffix).foregroundColor(.white)
    }
}
