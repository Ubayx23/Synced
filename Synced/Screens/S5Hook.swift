import SwiftUI

struct S5Hook: View {
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var phase = 0

    var body: some View {
        ScreenShell(progress: ScreenProgress.s5, onBack: onBack, ambient: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                LuminousOrb(diameter: 240, color: SYN.cyan)
                    .padding(.top, 8)

                Spacer().frame(height: 40)

                EyebrowTag(text: "Your personal insight")
                    .phaseFadeUp(phase: phase, delay: 0.0)

                Spacer().frame(height: 18)

                VStack(spacing: 12) {
                    Text("Imagine knowing exactly")
                        .font(.synDisplay(20, weight: .medium))
                        .foregroundStyle(SYN.textDim)
                        .phaseFadeUp(phase: phase, delay: 0.10)

                    headline
                        .multilineTextAlignment(.center)
                        .phaseFadeUp(phase: phase, delay: 0.25)

                    Text("And being able to do it again, on demand.")
                        .font(.synText(15))
                        .foregroundStyle(SYN.textDim)
                        .multilineTextAlignment(.center)
                        .phaseFadeUp(phase: phase, delay: 0.45)
                }
                .padding(.horizontal, 8)

                Spacer()
            }
            .background(
                RadialGradient(
                    colors: [SYN.cyan.opacity(0.22), SYN.cyan.opacity(0.06), .clear],
                    center: UnitPoint(x: 0.5, y: 0.32),
                    startRadius: 0, endRadius: 420
                )
                .allowsHitTesting(false)
                .blendMode(.plusLighter)
            )
        } cta: {
            PrimaryButton(title: "Tell me how", action: onNext)
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            withAnimation(.easeOut(duration: 0.7)) { phase = 1 }
        }
    }

    private var headline: Text {
        Text("why your last ")
            .font(.synDisplay(28, weight: .bold))
            .foregroundColor(.white)
        + Text("good lift")
            .font(.synDisplay(28, weight: .bold))
            .foregroundColor(SYN.cyan)
        + Text(" was good.")
            .font(.synDisplay(28, weight: .bold))
            .foregroundColor(.white)
    }
}
