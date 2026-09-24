import SwiftUI

/// Signed-out entry: brand moment plus two equal-weight routes, create an
/// account or sign in. The orb ties this screen to the launch animation.
struct WelcomeView: View {
    var onCreateAccount: () -> Void
    var onSignIn: () -> Void

    @State private var phase = 0

    var body: some View {
        ScreenShell(progress: nil, onBack: nil, ambient: true) {
            VStack(spacing: 0) {
                VStack(spacing: Spacing.m) {
                    SyncedWordmark(size: 56)
                        .shadow(color: SYN.cyan.opacity(0.4), radius: 20)
                    Text("Plan the week. Send the project.")
                        .font(.synText(17))
                        .foregroundStyle(SYN.textDim)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.xxl)
                .phaseFadeUp(phase: phase, delay: 0.05)

                Spacer(minLength: Spacing.lg)

                LuminousOrb(diameter: 200)
                    .accessibilityHidden(true)
                    .phaseFadeUp(phase: phase, delay: 0.15)

                Spacer(minLength: Spacing.lg)

                VStack(spacing: Spacing.md) {
                    PrimaryButton(title: "Create account", action: onCreateAccount)
                    SecondaryButton(title: "I already have an account", action: onSignIn)
                }
                .padding(.bottom, Spacing.lg)
                .phaseFadeUp(phase: phase, delay: 0.25)
            }
            .frame(maxWidth: .infinity)
        } cta: {
            Text("by creating an account you agree to our [Terms](https://synced.page/terms) and [Privacy Policy](https://synced.page/privacy)")
                .font(.synText(11))
                .foregroundStyle(SYN.textFaint)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .tint(SYN.cyan)
        }
        .task { withAnimation(.easeOut(duration: 0.4)) { phase = 1 } }
    }
}
