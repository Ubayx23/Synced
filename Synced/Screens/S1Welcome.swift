import SwiftUI

struct S1Welcome: View {
    var onNext: () -> Void
    @State private var phase = 0

    var body: some View {
        ScreenShell(progress: nil, onBack: nil) {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    PulseRingIcon(size: 96)
                        .scaleEffect(phase >= 1 ? 1 : 0.7)
                        .opacity(phase >= 1 ? 1 : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.78), value: phase)

                    SyncedWordmark(size: 56)
                        .shadow(color: SYN.cyan.opacity(0.45), radius: 22)
                        .phaseFadeUp(phase: phase, delay: 0.18)

                    Text("Train smarter. Recover harder.")
                        .font(.synText(17))
                        .foregroundStyle(SYN.textDim)
                        .phaseFadeUp(phase: phase, delay: 0.34)
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
            .phaseFadeUp(phase: phase, delay: 0.5)
        }
        .task { withAnimation { phase = 1 } }
    }
}
