import SwiftUI

struct S2Value: View {
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var currentCard: Int = 0
    @State private var visited: Set<Int> = []

    var body: some View {
        ScreenShell(progress: ScreenProgress.s2, onBack: onBack, ambient: false) {
            VStack(spacing: 0) {
                topProgress
                    .padding(.horizontal, Spacing.pageH)
                    .padding(.bottom, 4)

                TabView(selection: $currentCard) {
                    SmartCard(active: currentCard == 0, visited: visited.contains(0))
                        .tag(0)
                    PatternsCard(active: currentCard == 1, visited: visited.contains(1))
                        .tag(1)
                    ProgressInBothCard(active: currentCard == 2, visited: visited.contains(2))
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
            }
            .onAppear { visited.insert(currentCard) }
            .onChange(of: currentCard) { _, new in visited.insert(new) }
        } cta: {
            PrimaryButton(title: currentCard == 2 ? "Build my week" : "Continue") {
                if currentCard < 2 {
                    withAnimation(.easeInOut(duration: 0.35)) { currentCard += 1 }
                } else {
                    onNext()
                }
            }
        }
    }

    // Thin capsule bar at the top of the content area, marking the active card.
    private var topProgress: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { idx in
                Capsule()
                    .fill(idx == currentCard ? SYN.cyan : SYN.border)
                    .frame(width: idx == currentCard ? 22 : 6, height: 3)
                    .shadow(color: idx == currentCard ? SYN.cyan.opacity(0.5) : .clear, radius: 3)
            }
            Spacer()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentCard)
    }
}

// MARK: - Shared caption (headline + one-sentence body)

@ViewBuilder
private func valueCaption(headline: String, body: String) -> some View {
    VStack(alignment: .leading, spacing: 10) {
        Text(headline)
            .font(.synDisplay(28, weight: .bold))
            .foregroundStyle(SYN.text)
            .kerning(-0.5)
            .fixedSize(horizontal: false, vertical: true)
        Text(body)
            .font(.synText(15))
            .foregroundStyle(SYN.textDim)
            .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}

private func legendDot(color: Color, label: String) -> some View {
    HStack(spacing: 6) {
        Circle().fill(color).frame(width: 7, height: 7)
            .shadow(color: color.opacity(0.5), radius: 3)
        Text(label).font(.synText(12)).foregroundStyle(SYN.textDim)
    }
}

// MARK: - Card 1: Smart programming (kept)

private struct SmartCard: View {
    let active: Bool
    let visited: Bool

    private enum Slot { case lift, climb, rest }
    private let days = ["M", "T", "W", "T", "F", "S", "S"]
    private let week: [Slot] = [.lift, .climb, .rest, .lift, .climb, .lift, .rest]

    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            EyebrowText(text: "Lift days, climb days")
                .foregroundStyle(SYN.textFaint)
                .opacity(revealed ? 1 : 0)

            Spacer().frame(height: 18)

            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { idx in dayCell(idx) }
            }
            .frame(maxWidth: .infinity)

            Spacer().frame(height: 14)

            HStack(spacing: 18) {
                legendDot(color: SYN.cyan, label: "Lift")
                legendDot(color: SYN.green, label: "Climb")
                legendDot(color: SYN.textFaint, label: "Rest")
            }
            .opacity(revealed ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.5), value: revealed)

            Spacer().frame(height: 16)

            valueCaption(
                headline: "Lift and climb, on the right days.",
                body: "Synced spaces your heavy pulls and your hardest climbs so neither one steals the other's recovery."
            )
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 8)
            .animation(.easeOut(duration: 0.4).delay(0.55), value: revealed)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.pageH)
        .onAppear { if active || visited { revealed = true } }
        .onChange(of: active) { _, new in if new { revealed = true } }
    }

    private func dayCell(_ idx: Int) -> some View {
        VStack(spacing: 6) {
            Text(days[idx])
                .font(.synText(11, weight: .semibold))
                .foregroundStyle(accent(week[idx]))
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(week[idx] == .rest ? SYN.surface : accent(week[idx]).opacity(0.12))
                RoundedRectangle(cornerRadius: 10)
                    .stroke(week[idx] == .rest ? SYN.border : accent(week[idx]), lineWidth: week[idx] == .rest ? 1 : 1.5)
                icon(week[idx])
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent(week[idx]))
            }
            .frame(height: 46)
        }
        .opacity(revealed ? 1 : 0)
        .offset(y: revealed ? 0 : 12)
        .animation(.spring(response: 0.45, dampingFraction: 0.78).delay(0.05 + 0.05 * Double(idx)), value: revealed)
    }

    @ViewBuilder
    private func icon(_ slot: Slot) -> some View {
        switch slot {
        case .lift:  Image(systemName: "dumbbell.fill")
        case .climb: Image(systemName: "figure.climbing")
        case .rest:  EmptyView()
        }
    }

    private func accent(_ slot: Slot) -> Color {
        switch slot {
        case .lift:  return SYN.cyan
        case .climb: return SYN.green
        case .rest:  return SYN.textFaint
        }
    }
}

// MARK: - Card 2: Synced learns your patterns

private struct PatternsCard: View {
    let active: Bool
    let visited: Bool

    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            EyebrowText(text: "What Synced learns")
                .foregroundStyle(SYN.textFaint)
                .opacity(revealed ? 1 : 0)

            Spacer().frame(height: 18)

            insightCard
                .scaleEffect(revealed ? 1 : 0.96)
                .opacity(revealed ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(0.12), value: revealed)

            Spacer().frame(height: 16)

            valueCaption(
                headline: "Synced gets sharper as you log.",
                body: "It surfaces the patterns you would never catch yourself, like which lifts set up your best climbs."
            )
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 8)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: revealed)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.pageH)
        .onAppear { if active || visited { revealed = true } }
        .onChange(of: active) { _, new in if new { revealed = true } }
    }

    // Matches the in-app InsightCardView chrome.
    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Image(systemName: "figure.climbing")
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

            Spacer().frame(height: 8)

            Text("You climb two grades harder two days after leg day.")
                .font(.synDisplay(16, weight: .semibold))
                .foregroundStyle(SYN.text)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 6)

            Text("Avg V6 at 48hr rest vs V4 at 24hr.")
                .font(.synText(13))
                .foregroundStyle(SYN.textDim)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: Radius.card).fill(SYN.surface))
        .overlay(RoundedRectangle(cornerRadius: Radius.card).stroke(SYN.green.opacity(0.4), lineWidth: 1))
    }
}

// MARK: - Card 3: See progress in both

private struct ProgressInBothCard: View {
    let active: Bool
    let visited: Bool

    private let strengthPoints: [CGFloat] = [0.30, 0.36, 0.44, 0.52, 0.60, 0.72, 0.84]
    private let gradePoints:    [CGFloat] = [0.20, 0.24, 0.32, 0.40, 0.50, 0.62, 0.74]

    @State private var lineProgress: CGFloat = 0
    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            EyebrowText(text: "Progress in both")
                .foregroundStyle(SYN.textFaint)
                .opacity(revealed ? 1 : 0)

            Spacer().frame(height: 18)

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

            Spacer().frame(height: 12)

            HStack(spacing: 20) {
                legendDot(color: SYN.cyan, label: "Strength")
                legendDot(color: SYN.green, label: "Hardest grade")
            }
            .opacity(revealed ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: revealed)

            Spacer().frame(height: 16)

            valueCaption(
                headline: "Stronger and climbing harder, in one view.",
                body: "See whether your numbers and your grades are actually moving together, instead of guessing."
            )
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 8)
            .animation(.easeOut(duration: 0.4).delay(0.5), value: revealed)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.pageH)
        .onAppear { trigger() }
        .onChange(of: active) { _, _ in trigger() }
    }

    private func trigger() {
        guard active || visited else { return }
        revealed = true
        withAnimation(.easeOut(duration: 0.6).delay(0.15)) { lineProgress = 1 }
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
}

#Preview {
    S2Value(onBack: {}, onNext: {})
        .preferredColorScheme(.dark)
}
