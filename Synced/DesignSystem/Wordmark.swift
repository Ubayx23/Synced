import SwiftUI

/// Concentric pulse-ring icon — direct port of the SVG arcs from
/// synced-components.jsx lines 32-40.
struct PulseRingIcon: View {
    var size: CGFloat = 40
    var glow: Bool = true

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height)
            let scale = s / 40
            let cx = size.width / 2
            let cy = size.height / 2

            // Center cyan dot (r=3.2)
            let dotR = 3.2 * scale
            ctx.fill(
                Path(ellipseIn: CGRect(x: cx - dotR, y: cy - dotR, width: dotR * 2, height: dotR * 2)),
                with: .color(SYN.cyan)
            )

            // Inner arcs (r=12)
            let r1 = 12 * scale
            let arc1 = arcPath(center: CGPoint(x: cx, y: cy), radius: r1, start: -90, end: 0)
            let arc2 = arcPath(center: CGPoint(x: cx, y: cy), radius: r1, start: 90, end: 180)
            ctx.stroke(arc1, with: .color(SYN.cyan.opacity(0.95)),
                       style: StrokeStyle(lineWidth: 2.4 * scale, lineCap: .round))
            ctx.stroke(arc2, with: .color(SYN.cyan.opacity(0.95)),
                       style: StrokeStyle(lineWidth: 2.4 * scale, lineCap: .round))

            // Outer arcs (r=16)
            let r2 = 16 * scale
            let arc3 = arcPath(center: CGPoint(x: cx, y: cy), radius: r2, start: -118, end: -28)
            let arc4 = arcPath(center: CGPoint(x: cx, y: cy), radius: r2, start: 62, end: 152)
            ctx.stroke(arc3, with: .color(SYN.cyan.opacity(0.45)),
                       style: StrokeStyle(lineWidth: 1.6 * scale, lineCap: .round))
            ctx.stroke(arc4, with: .color(SYN.cyan.opacity(0.45)),
                       style: StrokeStyle(lineWidth: 1.6 * scale, lineCap: .round))
        }
        .frame(width: size, height: size)
        .shadow(color: glow ? SYN.cyan.opacity(0.55) : .clear, radius: glow ? 14 : 0)
    }

    private func arcPath(center: CGPoint, radius: CGFloat, start: Double, end: Double) -> Path {
        var p = Path()
        p.addArc(center: center,
                 radius: radius,
                 startAngle: .degrees(start),
                 endAngle: .degrees(end),
                 clockwise: false)
        return p
    }
}

/// "synced." wordmark with cyan period.
struct SyncedWordmark: View {
    var size: CGFloat = 48
    var body: some View {
        HStack(spacing: 0) {
            Text("synced")
                .font(.synDisplay(size, weight: .bold))
                .kerning(-size * 0.04)
                .foregroundStyle(.white)
            Text(".")
                .font(.synDisplay(size, weight: .bold))
                .foregroundStyle(SYN.cyan)
        }
    }
}

/// Welcome-screen logo lockup: pulse icon stacked above "synced." with a soft cyan halo.
struct SyncedLogoLockup: View {
    var iconSize: CGFloat = 88
    var wordSize: CGFloat = 56

    var body: some View {
        VStack(spacing: 24) {
            PulseRingIcon(size: iconSize)
            SyncedWordmark(size: wordSize)
                .shadow(color: SYN.cyan.opacity(0.35), radius: 18)
        }
        .background(
            Circle()
                .fill(SYN.cyan.opacity(0.18))
                .frame(width: iconSize * 4, height: iconSize * 4)
                .blur(radius: 80)
                .offset(y: -8)
                .allowsHitTesting(false)
        )
    }
}
