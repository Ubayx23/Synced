import SwiftUI

struct S8CheckInLoop: View {
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var phase = 0

    var body: some View {
        ScreenShell(progress: ScreenProgress.s8, onBack: onBack, ambient: false) {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowTag(text: "How it works")
                    .phaseFadeUp(phase: phase, delay: 0.05)

                Spacer().frame(height: 16)

                Text("Two check-ins per session.")
                    .font(.synDisplay(28, weight: .bold))
                    .foregroundStyle(.white)
                    .kerning(-0.9)
                    .shadow(color: SYN.cyan.opacity(0.25), radius: 12)
                    .phaseFadeUp(phase: phase, delay: 0.18)

                Spacer().frame(height: 10)

                Text("That's all Synced needs.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)
                    .phaseFadeUp(phase: phase, delay: 0.26)

                Spacer().frame(height: 32)

                VStack(spacing: 12) {
                    mockCard(title: "Pre-lift check-in",
                             subtitle: "Sleep, food, timing, hydration",
                             pillLabel: "Before")
                    mockCard(title: "Post-lift check-in",
                             subtitle: "Session feel, performance, notes",
                             pillLabel: "After")
                }
                .phaseFadeUp(phase: phase, delay: 0.34)

                Spacer().frame(height: 24)

                timingRow
                    .frame(maxWidth: .infinity)
                    .phaseFadeUp(phase: phase, delay: 0.45)

                Spacer().frame(height: 24)

                insightTeaser
                    .phaseFadeUp(phase: phase, delay: 0.55)

                Spacer()
            }
        } cta: {
            PrimaryButton(title: "Got it", action: onNext)
        }
        .task { withAnimation { phase = 1 } }
    }

    // MARK: - Mock check-in card

    private func mockCard(title: String, subtitle: String, pillLabel: String) -> some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.synDisplay(16, weight: .semibold))
                    .foregroundStyle(SYN.text)
                Text(subtitle)
                    .font(.synText(13))
                    .foregroundStyle(SYN.textDim)
            }

            Spacer()

            Text(pillLabel)
                .font(.synText(13, weight: .medium))
                .foregroundStyle(SYN.textDim)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SYN.surfaceHi)
                )
                .allowsHitTesting(false)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(SYN.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(SYN.border, lineWidth: 1)
        )
    }

    // MARK: - Timing row

    private var timingRow: some View {
        HStack(spacing: 0) {
            timingDot(label: "Before", filled: true)

            Rectangle()
                .fill(SYN.border)
                .frame(width: 60, height: 1)
                .padding(.horizontal, 8)
                .padding(.bottom, 18)

            timingDot(label: "After", filled: false)
        }
    }

    private func timingDot(label: String, filled: Bool) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(filled ? SYN.cyan : Color.clear)
                .overlay(Circle().stroke(filled ? SYN.cyan : SYN.border, lineWidth: 1.5))
                .frame(width: 8, height: 8)
            Text(label)
                .font(.synText(11))
                .foregroundStyle(SYN.textFaint)
        }
    }

    // MARK: - Insight teaser

    private var insightTeaser: some View {
        VStack(spacing: 8) {
            EyebrowText(text: "After 2 weeks")
                .foregroundStyle(SYN.textFaint)

            Text("You lift best after 7.5hrs sleep and chicken and rice 2 to 3hrs before your session.")
                .font(.synText(15, weight: .medium))
                .foregroundStyle(SYN.text)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            Text("Synced will figure this out for you.")
                .font(.synText(13))
                .foregroundStyle(SYN.textFaint)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(SYN.surfaceHi)
        )
    }
}
