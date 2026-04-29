import SwiftUI

/// Ambient cyan radial wash + slow breathing aura for screen backgrounds.
struct AmbientGlow: View {
    var enabled: Bool = true

    var body: some View {
        ZStack {
            // Static base wash, anchored top center.
            RadialGradient(
                colors: [
                    SYN.cyan.opacity(0.16),
                    SYN.cyan.opacity(0.04),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.0),
                startRadius: 0,
                endRadius: 520
            )
            .blendMode(.plusLighter)
            .allowsHitTesting(false)

            // Pulsing aura on top.
            if enabled {
                TimelineView(.animation(minimumInterval: 1.0 / 30, paused: false)) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    let breath = 0.5 + 0.5 * sin(t * 2 * .pi / 5.0)
                    RadialGradient(
                        colors: [
                            SYN.cyan.opacity(0.10 * breath),
                            .clear
                        ],
                        center: UnitPoint(x: 0.5, y: 0.18),
                        startRadius: 60,
                        endRadius: 360
                    )
                    .scaleEffect(0.94 + 0.10 * breath)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
                }
            }
        }
    }
}

/// Vignette-style background gradient used app-wide (matches the prototype's
/// `radial-gradient(1200px 700px at 50% 0%, #161616 0%, #0a0a0a 55%, #050505 100%)`).
struct ScreenBackground: View {
    var body: some View {
        RadialGradient(
            colors: [
                Color(hex: 0x161616),
                SYN.bg,
                SYN.bgDeep
            ],
            center: UnitPoint(x: 0.5, y: 0.0),
            startRadius: 0,
            endRadius: 760
        )
        .ignoresSafeArea()
    }
}
