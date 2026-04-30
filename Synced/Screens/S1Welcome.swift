import SwiftUI

struct S1Welcome: View {
    var onNext: () -> Void
    @State private var phase = 0

    var body: some View {
        ZStack {
            // Match the launch screen's solid black background so the
            // crossfade reads as new copy materializing around the existing
            // logo, not as a background shift.
            Color.black.ignoresSafeArea()
            content
        }
    }

    private var content: some View {
        ScreenShell(progress: nil, onBack: nil, ambient: false) {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    // Icon and wordmark are already fully visible when the
                    // launch screen finishes; do not re-animate them here.
                    PulseRingIcon(size: 96)

                    SyncedWordmark(size: 56)
                        .shadow(color: SYN.cyan.opacity(0.45), radius: 22)

                    Text("Train smarter. Recover harder.")
                        .font(.synText(17))
                        .foregroundStyle(SYN.textDim)
                        .phaseFadeUp(phase: phase, delay: 0.10)
                }
                .background(
                    Circle()
                        .fill(SYN.cyan.opacity(0.18))
                        .frame(width: 460, height: 460)
                        .blur(radius: 90)
                        .offset(y: -12)
                        .allowsHitTesting(false)
                )

                Spacer()
            }
        } cta: {
            VStack(spacing: 12) {
                PrimaryButton(title: "Get Started", action: onNext)
                TextLinkButton(title: "I already have an account") { /* future: sign-in */ }
            }
            .phaseFadeUp(phase: phase, delay: 0.25)
        }
        .task { withAnimation(.easeOut(duration: 0.4)) { phase = 1 } }
    }
}
