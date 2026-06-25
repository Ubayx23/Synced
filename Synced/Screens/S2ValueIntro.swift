import SwiftUI

struct S2ValueIntro: View {
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var currentCard: Int = 0
    @State private var phase = 0

    private struct ValueCard: Identifiable {
        let id: Int
        let icon: String
        let headline: String
        let body: String
    }

    private let cards: [ValueCard] = [
        .init(id: 0,
              icon: "figure.strengthtraining.traditional",
              headline: "Balance lifts and climbs.",
              body: "Most apps track one. Synced tracks both, so you know when to push and when to rest."),
        .init(id: 1,
              icon: "chart.line.uptrend.xyaxis",
              headline: "Get stronger in both.",
              body: "Watch your strength climb and your hardest send improve. Real progress, in real time."),
        .init(id: 2,
              icon: "sparkles",
              headline: "Trained by your data.",
              body: "After a few sessions, Synced shows you what your body actually responds to. Sleep, fuel, timing.")
    ]

    var body: some View {
        ScreenShell(progress: ScreenProgress.s2, onBack: onBack, ambient: false) {
            VStack(spacing: 0) {
                TabView(selection: $currentCard) {
                    ForEach(cards) { card in
                        cardView(card)
                            .tag(card.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                pageIndicator
                    .padding(.bottom, 24)
                    .phaseFadeUp(phase: phase, delay: 0.35)
            }
        } cta: {
            PrimaryButton(title: "Continue", action: onNext)
        }
        .task { withAnimation { phase = 1 } }
    }

    private func cardView(_ card: ValueCard) -> some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: card.icon)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(SYN.cyan)
                .shadow(color: SYN.cyan.opacity(0.45), radius: 18)

            Spacer().frame(height: 28)

            Text(card.headline)
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)
                .multilineTextAlignment(.center)
                .kerning(-0.5)
                .shadow(color: SYN.cyan.opacity(0.20), radius: 10)

            Spacer().frame(height: 14)

            Text(card.body)
                .font(.synText(15))
                .foregroundStyle(SYN.textDim)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.pageH)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<cards.count, id: \.self) { idx in
                Circle()
                    .fill(idx == currentCard ? SYN.cyan : SYN.border)
                    .frame(width: 6, height: 6)
                    .shadow(color: idx == currentCard ? SYN.cyan.opacity(0.6) : .clear,
                            radius: 4)
                    .animation(.easeInOut(duration: 0.2), value: currentCard)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    S2ValueIntro(onBack: {}, onNext: {})
        .preferredColorScheme(.dark)
}
