import SwiftUI
import Supabase

/// Sign-in screen for returning users, pushed from WelcomeView. The back
/// chevron returns to Welcome; "Create an account" switches to SignUpView.
struct SignInView: View {
    var onClose: () -> Void
    var onCreateAccount: (() -> Void)? = nil

    @Environment(SessionStore.self) private var session

    @State private var phase = 0
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var isSendingReset = false
    @State private var resetAlert: ResetAlert?

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
    }

    var body: some View {
        ScreenShell(progress: nil, onBack: onClose, ambient: false) {
            VStack(alignment: .leading, spacing: 0) {
                backRow
                    .padding(.bottom, Spacing.s)

                // Anchored to the top; the button and link follow the fields
                // directly, and any space below them is left empty.
                ScrollView {
                    form
                        .padding(.bottom, Spacing.lg)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .disabled(isSubmitting)
        .task { withAnimation { phase = 1 } }
        .alert(resetAlert?.title ?? "", isPresented: Binding(
            get: { resetAlert != nil },
            set: { if !$0 { resetAlert = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(resetAlert?.message ?? "")
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Smaller return of Welcome's wordmark, same cyan glow scaled down.
            SyncedWordmark(size: 26)
                .shadow(color: SYN.cyan.opacity(0.4), radius: 10)
                .phaseFadeUp(phase: phase, delay: 0.04)

            Spacer().frame(height: Spacing.md)

            Text("welcome back")
                .font(.synDisplay(30, weight: .heavy))
                .foregroundStyle(SYN.text)
                .kerning(-0.9)
                .shadow(color: SYN.cyan.opacity(0.25), radius: 12)
                .phaseFadeUp(phase: phase, delay: 0.10)

            Spacer().frame(height: Spacing.s)

            Text("sign in to pick up where you left off.")
                .font(.synText(15))
                .foregroundStyle(SYN.textDim)
                .frame(maxWidth: 320, alignment: .leading)
                .phaseFadeUp(phase: phase, delay: 0.18)

            Spacer().frame(height: Spacing.xl)

            SpecInput(
                value: $email,
                placeholder: "you@example.com",
                label: "Email",
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocap: .never
            )
            .phaseFadeUp(phase: phase, delay: 0.26)

            Spacer().frame(height: Spacing.md)

            SpecInput(
                value: $password,
                placeholder: "Your password",
                label: "Password",
                textContentType: .password,
                autocap: .never,
                isSecure: true
            )
            .phaseFadeUp(phase: phase, delay: 0.32)

            HStack {
                Spacer()
                Button(action: sendReset) {
                    Text(isSendingReset ? "Sending" : "Forgot password?")
                        .font(.synText(13, weight: .medium))
                        .foregroundStyle(SYN.cyan)
                        .frame(height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isSendingReset)
            }
            .padding(.top, Spacing.s)
            .phaseFadeUp(phase: phase, delay: 0.36)

            if let errorMessage {
                Spacer().frame(height: Spacing.s)
                Text(errorMessage)
                    .font(.synText(13))
                    .foregroundStyle(SYN.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Spacer().frame(height: Spacing.lg)

            PrimaryButton(title: "Log in", action: submit)
                .opacity(canSubmit ? 1 : 0.5)
                .disabled(!canSubmit)
                .allowsHitTesting(canSubmit)
                .phaseFadeUp(phase: phase, delay: 0.42)

            if let onCreateAccount {
                Spacer().frame(height: Spacing.md)
                TextLinkButton(title: "Create an account", action: onCreateAccount)
                    .frame(maxWidth: .infinity)
                    .phaseFadeUp(phase: phase, delay: 0.48)
            }
        }
    }

    /// Sends a Supabase reset email to whatever is in the email field.
    private func sendReset() {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmail.isEmpty else {
            resetAlert = ResetAlert(title: "Enter your email first", message: "Type the email you signed up with, then tap Forgot password? again.")
            return
        }
        isSendingReset = true
        Task {
            do {
                try await supabase.auth.resetPasswordForEmail(cleanEmail)
                resetAlert = ResetAlert(title: "Check your email", message: "If \(cleanEmail) has an account, a reset link is on its way.")
            } catch {
                resetAlert = ResetAlert(title: "Couldn't send a reset link", message: "Check your connection and try again.")
            }
            isSendingReset = false
        }
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
            .accessibilityLabel("Back")
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

private struct ResetAlert {
    let title: String
    let message: String
}
