import SwiftUI

struct S2Value: View {
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var phase = 0

    private struct Step: Identifiable {
        let id = UUID()
        let number: String
        let title: String
        let blurb: String
        let symbol: String
    }
    private let steps: [Step] = [
        Step(number: "01",
             title: "Tell us about you",
             blurb: "Goals, habits, sleep, recovery patterns.",
             symbol: "person.crop.circle.dashed"),
        Step(number: "02",
             title: "We watch you train",
             blurb: "We learn what works, and what wrecks you.",
             symbol: "chart.line.uptrend.xyaxis"),
        Step(number: "03",
             title: "You get smarter weekly",
             blurb: "Each Sunday you unlock the next layer.",
             symbol: "sparkles")
    ]

    var body: some View {
        ScreenShell(progress: ScreenProgress.s2, onBack: onBack) {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowTag(text: "How it works")
                    .phaseFadeUp(phase: phase, delay: 0.05)

                Spacer().frame(height: 20)

                (Text("Recovery you can ")
                    .foregroundColor(.white)
                 + Text("trust.")
                    .foregroundColor(SYN.cyan))
                    .font(.synDisplay(30, weight: .bold))
                    .kerning(-0.9)
                    .lineSpacing(2)
                    .shadow(color: SYN.cyan.opacity(0.25), radius: 12)
                    .phaseFadeUp(phase: phase, delay: 0.18)

                Spacer().frame(height: 14)

                Text("Three steps. No guesswork. Built for serious gym-goers.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)
                    .phaseFadeUp(phase: phase, delay: 0.30)

                Spacer().frame(height: 32)

                VStack(spacing: 14) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { idx, step in
                        valueCard(step)
                            .phaseFadeUp(phase: phase, delay: 0.40 + Double(idx) * 0.12)
                    }
                }

                Spacer()
            }
        } cta: {
            PrimaryButton(title: "Continue", action: onNext)
        }
        .task { withAnimation { phase = 1 } }
    }

    private func valueCard(_ s: Step) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(SYN.cyan.opacity(0.16))
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(SYN.cyan.opacity(0.45), lineWidth: 1))
                    .shadow(color: SYN.cyan.opacity(0.45), radius: 12)
                Image(systemName: s.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SYN.cyan)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(s.title)
                    .font(.synText(16, weight: .semibold))
                    .foregroundStyle(.white)
                Text(s.blurb)
                    .font(.synText(13))
                    .foregroundStyle(SYN.textDim)
            }

            Spacer()

            Text(s.number)
                .font(.synMono(14, weight: .medium))
                .foregroundStyle(SYN.cyan.opacity(0.8))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x1A1A1E), Color(hex: 0x131316)],
                                     startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            HStack(spacing: 0) {
                Rectangle()
                    .fill(SYN.cyan)
                    .frame(width: 2)
                    .shadow(color: SYN.cyan.opacity(0.7), radius: 6)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(SYN.border, lineWidth: 1)
        )
    }
}
