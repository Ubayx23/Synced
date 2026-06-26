import SwiftUI

struct S2ValueIntro: View {
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var currentCard: Int = 0
    @State private var visited: Set<Int> = []

    var body: some View {
        ScreenShell(progress: ScreenProgress.s2, onBack: onBack, ambient: false) {
            VStack(spacing: 0) {
                TabView(selection: $currentCard) {
                    BalanceCard(active: currentCard == 0, visited: visited.contains(0))
                        .tag(0)
                    ProgressCard(active: currentCard == 1, visited: visited.contains(1))
                        .tag(1)
                    InsightPreviewCard(active: currentCard == 2, visited: visited.contains(2))
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                pageIndicator
                    .padding(.bottom, 12)
            }
            .onAppear { visited.insert(currentCard) }
            .onChange(of: currentCard) { _, new in visited.insert(new) }
        } cta: {
            PrimaryButton(title: currentCard == 2 ? "I'm in" : "Continue") {
                if currentCard < 2 {
                    withAnimation(.easeInOut(duration: 0.3)) { currentCard += 1 }
                } else {
                    onNext()
                }
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { idx in
                Capsule()
                    .fill(idx == currentCard ? SYN.cyan : SYN.border)
                    .frame(width: idx == currentCard ? 20 : 6, height: 6)
                    .shadow(color: idx == currentCard ? SYN.cyan.opacity(0.6) : .clear, radius: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: currentCard)
            }
        }
    }
}

// MARK: - Card 1: Balance lifts and climbs

private struct BalanceCard: View {
    let active: Bool
    let visited: Bool

    private let days = ["M", "T", "W", "T", "F", "S", "S"]
    private enum Slot { case lift, climb, rest }
    private let week: [Slot] = [.lift, .rest, .climb, .lift, .rest, .climb, .lift]

    @State private var revealed: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            EyebrowText(text: "Your week, scheduled")
                .foregroundStyle(SYN.textFaint)
                .opacity(revealed ? 1 : 0)

            Spacer().frame(height: 18)

            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { idx in
                    VStack(spacing: 6) {
                        Text(days[idx])
                            .font(.synText(11, weight: .semibold))
                            .foregroundStyle(SYN.textFaint)
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(SYN.surface)
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(strokeFor(week[idx]).opacity(0.5), lineWidth: 1)
                            iconFor(week[idx])
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(strokeFor(week[idx]))
                        }
                        .frame(width: 36, height: 44)
                        .shadow(color: strokeFor(week[idx]).opacity(0.25), radius: 4)
                        .opacity(revealed ? 1 : 0)
                        .offset(y: revealed ? 0 : 12)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.78)
                                .delay(0.05 + 0.05 * Double(idx)),
                            value: revealed
                        )
                    }
                }
            }
            .padding(.horizontal, Spacing.pageH)

            Spacer().frame(height: 44)

            cardCopy(
                headline: "Balance lifts and climbs.",
                body: "Most apps track one. Synced tracks both, so you know when to push and when to rest."
            )
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 8)
            .animation(.easeOut(duration: 0.4).delay(0.55), value: revealed)

            Spacer()
            Spacer()
        }
        .onAppear { if active || visited { revealed = true } }
        .onChange(of: active) { _, new in if new { revealed = true } }
    }

    @ViewBuilder
    private func iconFor(_ slot: Slot) -> some View {
        switch slot {
        case .lift:  Image(systemName: "dumbbell.fill")
        case .climb: Image(systemName: "figure.climbing")
        case .rest:  Image(systemName: "moon.fill")
        }
    }

    private func strokeFor(_ slot: Slot) -> Color {
        switch slot {
        case .lift:  return SYN.cyan
        case .climb: return SYN.green
        case .rest:  return SYN.textFaint
        }
    }
}

// MARK: - Card 2: Get stronger in both

private struct ProgressCard: View {
    let active: Bool
    let visited: Bool

    private let strengthPoints: [CGFloat] = [0.28, 0.34, 0.42, 0.5, 0.58, 0.7, 0.82]
    private let gradePoints:    [CGFloat] = [0.18, 0.22, 0.3,  0.38, 0.48, 0.6, 0.72]

    @State private var lineProgress: CGFloat = 0
    @State private var revealed: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            EyebrowText(text: "12-week trend")
                .foregroundStyle(SYN.textFaint)
                .opacity(revealed ? 1 : 0)

            Spacer().frame(height: 20)

            GeometryReader { geo in
                ZStack {
                    VStack(spacing: 0) {
                        ForEach(0..<5, id: \.self) { _ in
                            Spacer()
                            Rectangle().fill(SYN.border.opacity(0.4)).frame(height: 0.5)
                        }
                    }
                    chartLine(points: gradePoints, color: SYN.green, size: geo.size)
                    chartLine(points: strengthPoints, color: SYN.cyan, size: geo.size)
                }
            }
            .frame(height: 140)
            .padding(.horizontal, Spacing.pageH)

            Spacer().frame(height: 14)

            HStack(spacing: 24) {
                legendItem(color: SYN.cyan, label: "Strength")
                legendItem(color: SYN.green, label: "Hardest grade")
            }
            .opacity(revealed ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: revealed)

            Spacer().frame(height: 36)

            cardCopy(
                headline: "Get stronger in both.",
                body: "Watch your strength climb and your hardest send improve. Real progress, in real time."
            )
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 8)
            .animation(.easeOut(duration: 0.4).delay(0.55), value: revealed)

            Spacer()
            Spacer()
        }
        .onAppear { triggerIfActive() }
        .onChange(of: active) { _, _ in triggerIfActive() }
    }

    private func triggerIfActive() {
        guard active || visited else { return }
        revealed = true
        withAnimation(.easeOut(duration: 1.0).delay(0.15)) {
            lineProgress = 1
        }
    }

    private func chartLine(points: [CGFloat], color: Color, size: CGSize) -> some View {
        Path { path in
            let step = size.width / CGFloat(points.count - 1)
            let cutoff = Int((CGFloat(points.count - 1) * lineProgress).rounded(.up))
            let visiblePoints = max(1, min(points.count, cutoff + 1))
            for i in 0..<visiblePoints {
                let x = CGFloat(i) * step
                let y = size.height * (1 - points[i])
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else      { path.addLine(to: CGPoint(x: x, y: y)) }
            }
        }
        .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        .shadow(color: color.opacity(0.45), radius: 5)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.5), radius: 3)
            Text(label).font(.synText(12)).foregroundStyle(SYN.textDim)
        }
    }
}

// MARK: - Card 3: Trained by your data

private struct InsightPreviewCard: View {
    let active: Bool
    let visited: Bool

    @State private var revealed: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            EyebrowText(text: "After your first 14 sessions")
                .foregroundStyle(SYN.textFaint)
                .opacity(revealed ? 1 : 0)

            Spacer().frame(height: 18)

            // Mock insight card matching the in-app InsightCardView style.
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(SYN.green)
                    Spacer()
                    Text("Based on 14 sessions")
                        .font(.synText(11))
                        .foregroundStyle(SYN.textFaint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 999).fill(SYN.surfaceHi))
                        .overlay(RoundedRectangle(cornerRadius: 999).stroke(SYN.border, lineWidth: 1))
                }

                Spacer().frame(height: 12)

                Text("You climb 30% better 48hrs after a legs day.")
                    .font(.synDisplay(16, weight: .semibold))
                    .foregroundStyle(SYN.text)
                    .multilineTextAlignment(.leading)

                Spacer().frame(height: 6)

                Text("Avg send grade 4.3 with 48hr rest vs 3.1 with 24hr.")
                    .font(.synText(13))
                    .foregroundStyle(SYN.textDim)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.card).fill(SYN.surface))
            .overlay(RoundedRectangle(cornerRadius: Radius.card).stroke(SYN.green.opacity(0.4), lineWidth: 1))
            .padding(.horizontal, Spacing.pageH)
            .scaleEffect(revealed ? 1 : 0.94)
            .opacity(revealed ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.15), value: revealed)

            Spacer().frame(height: 36)

            cardCopy(
                headline: "Trained by your data.",
                body: "After a few sessions, Synced shows you what your body actually responds to."
            )
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 8)
            .animation(.easeOut(duration: 0.4).delay(0.55), value: revealed)

            Spacer()
            Spacer()
        }
        .onAppear { if active || visited { revealed = true } }
        .onChange(of: active) { _, new in if new { revealed = true } }
    }
}

// MARK: - Shared card copy

@ViewBuilder
private func cardCopy(headline: String, body: String) -> some View {
    VStack(spacing: 12) {
        Text(headline)
            .font(.synDisplay(28, weight: .bold))
            .foregroundStyle(SYN.text)
            .kerning(-0.5)
            .multilineTextAlignment(.center)
            .shadow(color: SYN.cyan.opacity(0.20), radius: 10)

        Text(body)
            .font(.synText(15))
            .foregroundStyle(SYN.textDim)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 300)
    }
    .padding(.horizontal, Spacing.pageH)
}

#Preview {
    S2ValueIntro(onBack: {}, onNext: {})
        .preferredColorScheme(.dark)
}
