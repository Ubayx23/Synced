import SwiftUI
import AuthenticationServices
import CryptoKit
import Supabase

/// First account-creation screen. Sits in onboarding between S9Notifications
/// and S12TierReveal. Wiring into OnboardingFlow's switch is a separate task,
/// so the step number and progress value are local constants for now.
struct SignUpView: View {
    var onBack: () -> Void
    var onSuccess: () -> Void

    @State private var phase = 0
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var currentNonce: String?

    var body: some View {
        ScreenShell(progress: ScreenProgress.signUp, onBack: onBack, ambient: false) {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowTag(text: "Step \(ScreenProgress.signUpStep) of \(ScreenProgress.total)")
                    .phaseFadeUp(phase: phase, delay: 0.05)

                Spacer().frame(height: 16)

                Text("create your account")
                    .font(.synDisplay(30, weight: .heavy))
                    .foregroundStyle(SYN.text)
                    .kerning(-0.9)
                    .shadow(color: SYN.cyan.opacity(0.25), radius: 12)
                    .phaseFadeUp(phase: phase, delay: 0.18)

                Spacer().frame(height: 10)

                Text("we'll save your goals and check-ins.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)
                    .frame(maxWidth: 320, alignment: .leading)
                    .phaseFadeUp(phase: phase, delay: 0.26)

                Spacer().frame(height: 32)

                appleButton
                    .phaseFadeUp(phase: phase, delay: 0.34)

                Spacer().frame(height: 20)

                orDivider
                    .phaseFadeUp(phase: phase, delay: 0.40)

                Spacer().frame(height: 20)

                SpecInput(
                    value: $email,
                    placeholder: "you@example.com",
                    label: "Email",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocap: .never
                )
                .phaseFadeUp(phase: phase, delay: 0.46)

                Spacer().frame(height: 16)

                SpecInput(
                    value: $password,
                    placeholder: "At least 6 characters",
                    label: "Password",
                    textContentType: .newPassword,
                    autocap: .never,
                    isSecure: true
                )
                .phaseFadeUp(phase: phase, delay: 0.52)

                Spacer().frame(height: 20)

                HStack {
                    Spacer()
                    TextLinkButton(title: "create with email", action: submitEmail)
                    Spacer()
                }
                .phaseFadeUp(phase: phase, delay: 0.58)

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
            Text("by continuing you agree to our terms and privacy policy.")
                .font(.synText(11))
                .foregroundStyle(SYN.textFaint)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .disabled(isSubmitting)
        .task { withAnimation { phase = 1 } }
    }

    // MARK: - Apple button

    private var appleButton: some View {
        SignInWithAppleButton(.continue) { request in
            let nonce = randomNonceString()
            currentNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
        } onCompletion: { result in
            handleAppleCompletion(result)
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 56)
        .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
        .opacity(isSubmitting ? 0.5 : 1)
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(SYN.border).frame(height: 1)
            Text("or")
                .font(.synText(12, weight: .semibold))
                .tracking(1.0)
                .textCase(.uppercase)
                .foregroundStyle(SYN.textFaint)
            Rectangle().fill(SYN.border).frame(height: 1)
        }
    }

    // MARK: - Auth flow

    /// Runs an auth action, then writes the onboarding profile, then advances.
    /// Any thrown error surfaces inline and blocks navigation.
    private func submit(_ authAction: @escaping () async throws -> Void) {
        guard !isSubmitting else { return }
        errorMessage = nil
        isSubmitting = true
        Task {
            do {
                try await authAction()
                try await writeProfile()
                isSubmitting = false
                onSuccess()
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func submitEmail() {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmail.isEmpty, password.count >= 6 else {
            errorMessage = "Enter an email and a password of at least 6 characters."
            return
        }
        submit {
            _ = try await supabase.auth.signUp(email: cleanEmail, password: password)
        }
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let tokenString = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else {
                errorMessage = "Apple sign in failed. Please try again."
                return
            }
            submit {
                _ = try await supabase.auth.signInWithIdToken(
                    credentials: .init(provider: .apple, idToken: tokenString, nonce: nonce)
                )
            }
        }
    }

    /// Writes the onboarding answers held in UserDefaults into the user's
    /// profiles row. The profiles table has no age column, so userAge is not
    /// persisted here.
    private func writeProfile() async throws {
        let userID = try await supabase.auth.session.user.id
        let defaults = UserDefaults.standard
        let row = ProfileRow(
            id: userID,
            username: defaults.string(forKey: "userName") ?? "",
            training_goal: defaults.string(forKey: "trainingGoal") ?? "",
            training_frequency: defaults.object(forKey: "trainingFrequency") as? Int ?? 4,
            sleep_baseline: defaults.object(forKey: "sleepBaseline") as? Double ?? 7.5
        )
        try await supabase.from("profiles").upsert(row).execute()
    }

    // MARK: - Nonce helpers

    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }
            for random in randoms {
                if remaining == 0 { break }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

// MARK: - Profile row

private struct ProfileRow: Encodable {
    let id: UUID
    let username: String
    let training_goal: String
    let training_frequency: Int
    let sleep_baseline: Double
}

#Preview {
    ZStack {
        SYN.bg.ignoresSafeArea()
        SignUpView(onBack: {}, onSuccess: {})
    }
    .preferredColorScheme(.dark)
}
