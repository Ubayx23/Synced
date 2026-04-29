import SwiftUI

struct S3Name: View {
    var model: OnboardingModel
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var phase = 0
    @State private var firstName: String = ""

    private var trimmed: String {
        firstName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var isValid: Bool { trimmed.count >= 2 }

    var body: some View {
        ScreenShell(progress: ScreenProgress.s3, onBack: onBack) {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowTag(text: "About you")
                    .phaseFadeUp(phase: phase, delay: 0.05)

                Spacer().frame(height: 20)

                (Text("What's your ")
                    .foregroundColor(.white)
                 + Text("name?")
                    .foregroundColor(SYN.cyan))
                    .font(.synDisplay(30, weight: .bold))
                    .kerning(-0.9)
                    .shadow(color: SYN.cyan.opacity(0.25), radius: 12)
                    .phaseFadeUp(phase: phase, delay: 0.18)

                Spacer().frame(height: 12)

                Text("We'll personalize your experience.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)
                    .phaseFadeUp(phase: phase, delay: 0.30)

                Spacer().frame(height: 40)

                SpecInput(
                    value: $firstName,
                    placeholder: "Enter your first name",
                    label: "First name",
                    autocap: .words,
                    maxLength: 24,
                    isValid: trimmed.isEmpty ? nil : isValid,
                    autoFocus: true
                )
                .phaseFadeUp(phase: phase, delay: 0.42)

                Spacer()
            }
        } cta: {
            PrimaryButton(title: "Continue", disabled: !isValid) {
                model.firstName = trimmed
                UserDefaults.standard.set(trimmed, forKey: "userName")
                onNext()
            }
        }
        .onAppear {
            firstName = model.firstName
        }
        .task { withAnimation { phase = 1 } }
    }
}
