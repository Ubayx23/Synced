import SwiftUI
import Supabase

/// Sign-in screen for returning users. Presented as a full-screen cover from
/// S1Welcome via the "I already have an account" link.
struct SignInView: View {
    var onClose: () -> Void

    @Environment(SessionStore.self) private var session

    @State private var phase = 0
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
    }

    var body: some View {
        ScreenShell(progress: nil, onBack: onClose, ambient: false) {
            VStack(alignment: .leading, spacing: 0) {
                backRow
                    .padding(.bottom, 8)

                Text("welcome back")
                    .font(.synDisplay(30, weight: .heavy))
                    .foregroundStyle(SYN.text)
                    .kerning(-0.9)
                    .shadow(color: SYN.cyan.opacity(0.25), radius: 12)
                    .phaseFadeUp(phase: phase, delay: 0.10)

                Spacer().frame(height: 10)

                Text("sign in to pick up where you left off.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)
                    .frame(maxWidth: 320, alignment: .leading)
                    .phaseFadeUp(phase: phase, delay: 0.18)

                Spacer().frame(height: 32)

                SpecInput(
                    value: $email,
                    placeholder: "you@example.com",
                    label: "Email",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocap: .never
                )
                .phaseFadeUp(phase: phase, delay: 0.26)

                Spacer().frame(height: 16)

                SpecInput(
                    value: $password,
                    placeholder: "Your password",
                    label: "Password",
                    textContentType: .password,
                    autocap: .never,
                    isSecure: true
                )
                .phaseFadeUp(phase: phase, delay: 0.32)

                if let errorMessage {
                    Spacer().frame(height: 16)
                    Text(errorMessage)
                        .font(.synText(13))
                        .foregroundStyle(SYN.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                Spacer()
            }
        } cta: {
            PrimaryButton(title: "Log in", action: submit)
                .opacity(canSubmit ? 1 : 0.5)
                .disabled(!canSubmit)
                .allowsHitTesting(canSubmit)
        }
        .disabled(isSubmitting)
        .task { withAnimation { phase = 1 } }
    }

    private var backRow: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(SYN.textDim)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private func submit() {
        guard !isSubmitting, canSubmit else { return }
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil
        isSubmitting = true
        Task {
            do {
                try await supabase.auth.signIn(email: cleanEmail, password: password)
                await MainActor.run {
                    isSubmitting = false
                    session.markSignedIn()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ZStack {
        SYN.bg.ignoresSafeArea()
        SignInView(onClose: {})
            .environment(SessionStore())
    }
    .preferredColorScheme(.dark)
}
