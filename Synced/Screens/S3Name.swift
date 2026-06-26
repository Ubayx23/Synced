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

    // Capitalized live name, falling back to the same default Home uses.
    private var previewName: String {
        guard !trimmed.isEmpty else { return "there" }
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
    }

    var body: some View {
        ScreenShell(progress: ScreenProgress.s3, onBack: onBack, ambient: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("What should we call you?")
                    .font(.synDisplay(30, weight: .bold))
                    .foregroundStyle(SYN.text)
                    .kerning(-0.9)
                    .shadow(color: SYN.cyan.opacity(0.25), radius: 12)
                    .phaseFadeUp(phase: phase, delay: 0.18)

                Spacer().frame(height: 12)

                Text("This is how Synced greets you each morning.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)
                    .phaseFadeUp(phase: phase, delay: 0.30)

                Spacer()

                greetingPreview
                    .phaseFadeUp(phase: phase, delay: 0.42)

                Spacer().frame(height: 24)

                SpecInput(
                    value: $firstName,
                    placeholder: "Enter your first name",
                    label: "First name",
                    autocap: .words,
                    maxLength: 24,
                    isValid: trimmed.isEmpty ? nil : isValid,
                    autoFocus: true
                )
                .phaseFadeUp(phase: phase, delay: 0.50)

                Spacer().frame(height: 28)
            }
        } cta: {
            PrimaryButton(title: "Continue", disabled: !isValid) {
                model.firstName = previewName
                UserDefaults.standard.set(previewName, forKey: "userName")
                onNext()
            }
            .scaleEffect(isValid ? 1 : 0.98)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isValid)
        }
        .onAppear { firstName = model.firstName }
        .task { withAnimation { phase = 1 } }
    }

    // Live mock of the Home greeting, matching HomeView's header so it reads as
    // a genuine preview of the product rather than an illustration.
    private var greetingPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            EyebrowText(text: "On your home screen")
                .foregroundStyle(SYN.textFaint)

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Good morning,")
                        .font(.synText(14))
                        .foregroundStyle(SYN.textDim)
                    Text(previewName)
                        .font(.synDisplay(20, weight: .bold))
                        .foregroundStyle(trimmed.isEmpty ? SYN.textFaint : SYN.text)
                        .animation(.easeOut(duration: 0.18), value: previewName)
                }
                Spacer()
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(SYN.textDim)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.card).fill(SYN.surface))
            .overlay(RoundedRectangle(cornerRadius: Radius.card).stroke(SYN.border, lineWidth: 1))
        }
    }
}
