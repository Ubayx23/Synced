import SwiftUI

/// Animated splash that runs once on cold launch. Sequence:
/// dot springs in → inner arc draws → outer arc draws → wordmark fades up
/// → 0.3s hold → onComplete fires (parent fades out).
struct LaunchScreen: View {
    let onComplete: () -> Void

    @State private var dotScale: CGFloat = 0
    @State private var dotGlowScale: CGFloat = 0.5
    @State private var dotGlowOpacity: Double = 0.15
    @State private var innerArcProgress: CGFloat = 0
    @State private var outerArcProgress: CGFloat = 0
    @State private var outerArcOpacity: Double = 0.7
    @State private var wordmarkOpacity: Double = 0
    @State private var wordmarkOffset: CGFloat = 12

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(spacing: 20) {
                iconGroup
                    .frame(width: 60, height: 60)

                SyncedWordmark(size: 56)
                    .shadow(color: SYN.cyan.opacity(0.45), radius: 22)
                    .opacity(wordmarkOpacity)
                    .offset(y: wordmarkOffset)
            }
        }
        .onAppear { runAnimation() }
    }

    // MARK: - Icon

    private var iconGroup: some View {
        ZStack {
            // Glow pulse expanding behind the dot.
            Circle()
                .fill(SYN.cyan)
                .frame(width: 32, height: 32)
                .scaleEffect(dotGlowScale)
                .opacity(dotGlowOpacity)

            // Outer arc — 52pt ring.
            Circle()
                .trim(from: 0.325, to: 0.325 + outerArcProgress)
                .stroke(SYN.cyan,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .frame(width: 52, height: 52)
                .rotationEffect(.degrees(-210))
                .opacity(outerArcOpacity)

            // Inner arc — 32pt ring.
            Circle()
                .trim(from: 0.325, to: 0.325 + innerArcProgress)
                .stroke(SYN.cyan,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(-210))

            // Center dot (last so it sits on top of the glow).
            Circle()
                .fill(SYN.cyan)
                .frame(width: 8, height: 8)
                .scaleEffect(dotScale)
        }
    }

    // MARK: - Animation timeline

    private func runAnimation() {
        // Phase 1 — dot springs in, glow ripples out.
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            dotScale = 1.0
        }
        withAnimation(.easeOut(duration: 0.4)) {
            dotGlowScale = 1.5
            dotGlowOpacity = 0
        }

        // Phase 2 — inner arc.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.4)) {
                innerArcProgress = 0.35
            }
        }

        // Phase 3 — outer arc, slightly softer arrival.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeOut(duration: 0.45)) {
                outerArcProgress = 0.35
                outerArcOpacity = 1.0
            }
        }

        // Phase 4 — wordmark fades up.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            withAnimation(.easeOut(duration: 0.45)) {
                wordmarkOpacity = 1.0
                wordmarkOffset = 0
            }
        }

        // Phase 5 — hold then hand off. Parent owns the cross-fade.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onComplete()
        }
    }
}
