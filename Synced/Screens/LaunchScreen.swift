import SwiftUI

/// Animated splash. Layout mirrors `S1Welcome` exactly so the icon and
/// wordmark land at the same screen position on either side of the crossfade.
struct LaunchScreen: View {
    let onComplete: () -> Void

    @State private var dotScale: CGFloat = 0
    @State private var dotGlowScale: CGFloat = 0.5
    @State private var dotGlowOpacity: Double = 0.18
    @State private var innerArcsProgress: CGFloat = 0
    @State private var outerArcsProgress: CGFloat = 0
    @State private var wordmarkOpacity: Double = 0
    @State private var wordmarkOffset: CGFloat = 12

    private let iconSize: CGFloat = 96

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScreenShell(progress: nil, onBack: nil, ambient: false) {
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 28) {
                        icon
                            .frame(width: iconSize, height: iconSize)

                        SyncedWordmark(size: 56)
                            .shadow(color: SYN.cyan.opacity(0.45), radius: 22)
                            .opacity(wordmarkOpacity)
                            .offset(y: wordmarkOffset)

                        // Invisible spacer matching Welcome's tagline height so
                        // the centered VStack settles at the same y-position.
                        Text("Train smarter. Recover harder.")
                            .font(.synText(17))
                            .opacity(0)
                    }

                    Spacer()
                }
            } cta: {
                // Reserves the same CTA height as Welcome (button + link) so
                // the centering geometry above stays identical.
                VStack(spacing: 12) {
                    Color.clear.frame(height: 56)
                    Color.clear.frame(height: 22)
                }
            }
        }
        .onAppear { runAnimation() }
    }

    // MARK: - Icon (mirrors PulseRingIcon geometry)

    private var icon: some View {
        ZStack {
            // Soft glow ripple radiating from the dot.
            Circle()
                .fill(SYN.cyan)
                .frame(width: iconSize * 0.5, height: iconSize * 0.5)
                .scaleEffect(dotGlowScale)
                .opacity(dotGlowOpacity)

            // Outer arcs.
            outerArc(start: -118, end: -28)
            outerArc(start: 62,   end: 152)

            // Inner arcs.
            innerArc(start: -90, end: 0)
            innerArc(start: 90,  end: 180)

            // Center dot.
            Circle()
                .fill(SYN.cyan)
                .frame(width: iconSize * 0.16, height: iconSize * 0.16)
                .scaleEffect(dotScale)
                .shadow(color: SYN.cyan.opacity(0.6), radius: 8)
        }
    }

    private func innerArc(start: Double, end: Double) -> some View {
        Arc(start: start, end: end)
            .trim(from: 0, to: innerArcsProgress)
            .stroke(
                SYN.cyan.opacity(0.95),
                style: StrokeStyle(lineWidth: iconSize * 0.06, lineCap: .round)
            )
            .frame(width: iconSize * 0.6, height: iconSize * 0.6)
    }

    private func outerArc(start: Double, end: Double) -> some View {
        Arc(start: start, end: end)
            .trim(from: 0, to: outerArcsProgress)
            .stroke(
                SYN.cyan.opacity(0.55),
                style: StrokeStyle(lineWidth: iconSize * 0.04, lineCap: .round)
            )
            .frame(width: iconSize * 0.8, height: iconSize * 0.8)
    }

    // MARK: - Animation timeline

    private func runAnimation() {
        // Phase 1 — dot springs in, glow ripples out.
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            dotScale = 1.0
        }
        withAnimation(.easeOut(duration: 0.45)) {
            dotGlowScale = 1.6
            dotGlowOpacity = 0
        }

        // Phase 2 — inner arcs draw in.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.45)) {
                innerArcsProgress = 1.0
            }
        }

        // Phase 3 — outer arcs draw in.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
            withAnimation(.easeOut(duration: 0.55)) {
                outerArcsProgress = 1.0
            }
        }

        // Phase 4 — wordmark.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            withAnimation(.easeOut(duration: 0.45)) {
                wordmarkOpacity = 1.0
                wordmarkOffset = 0
            }
        }

        // Phase 5 — hold, then hand off. Parent owns the crossfade.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onComplete()
        }
    }
}

// MARK: - Arc shape

private struct Arc: Shape {
    let start: Double  // degrees
    let end: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        p.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(start),
            endAngle: .degrees(end),
            clockwise: false
        )
        return p
    }
}
