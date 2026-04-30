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
        ScreenShell(progress: ScreenProgress.s3, onBack: onBack, ambient: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("What's your name?")
                    .font(.synDisplay(30, weight: .bold))
                    .foregroundStyle(SYN.text)
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
                let formatted = trimmed.prefix(1).uppercased() + trimmed.dropFirst()
                model.firstName = formatted
                UserDefaults.standard.set(formatted, forKey: "userName")
                onNext()
            }
        }
        .onAppear {
            firstName = model.firstName
        }
        .task { withAnimation { phase = 1 } }
    }
}
