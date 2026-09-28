import SwiftUI

/// How strong the ambient glow is. Subtle is the original look; hero is for
/// headline moments (Welcome, Recovery, Progress headline).
enum GlowIntensity {
    case subtle
    case hero

    /// Peak opacity of the static wash at its center. Hero is about double
    /// subtle; at 0.6 the wash washed out the Welcome tagline and the
    /// Progress headline, so it is held at 0.3 to keep text readable.
    var washPeak: Double {
        switch self {
        case .subtle: return 0.16
        case .hero:   return 0.3
        }
    }

    /// Radii scale; hero reaches about 1.5x further.
    var radiusScale: CGFloat {
        switch self {
        case .subtle: return 1.0
        case .hero:   return 1.5
        }
    }
}

/// Ambient cyan radial wash + slow breathing aura for screen backgrounds.
/// Same math at both intensities; hero scales opacity and radius.
struct AmbientGlow: View {
    var enabled: Bool = true
    var intensity: GlowIntensity = .subtle

    var body: some View {
        // Keeps the original proportions: the mid stop and the aura peak
        // are a fixed share of the wash peak (0.04 and 0.10 against 0.16).
        let peak = intensity.washPeak
        let scale = intensity.radiusScale

        ZStack {
            // Static base wash, anchored top center.
            RadialGradient(
                colors: [
                    SYN.cyan.opacity(peak),
                    SYN.cyan.opacity(peak * 0.25),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.0),
                startRadius: 0,
                endRadius: 520 * scale
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
                            SYN.cyan.opacity(peak * 0.625 * breath),
                            .clear
                        ],
                        center: UnitPoint(x: 0.5, y: 0.18),
                        startRadius: 60 * scale,
                        endRadius: 360 * scale
                    )
                    .scaleEffect(0.94 + 0.10 * breath)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
                }
            }
        }
    }
}

/// Hero glow placed behind a specific region rather than a whole screen.
/// The wash starts at the frame's top edge, so the frame is oversized and
/// faded at the top and bottom to avoid hard edges where it is brightest.
struct HeroGlow: View {
    var width: CGFloat = 820
    var height: CGFloat = 760

    var body: some View {
        AmbientGlow(intensity: .hero)
            .frame(width: width, height: height)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.18),
                        .init(color: .black, location: 0.6),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
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
