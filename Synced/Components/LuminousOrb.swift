import SwiftUI

/// 240×240 luminous orb with three orbital rings and a pulsing core.
/// Used on S5 (hook) and S12 (tier reveal) — color/icon vary by usage.
struct LuminousOrb: View {
    var diameter: CGFloat = 240
    var color: Color = SYN.cyan
    var icon: AnyView? = nil
    /// Tier reveal mode renders the inner core in the tier's color rather than
    /// the cyan→white default.
    var tierMode: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? .greatestFiniteMagnitude : 1.0 / 60)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let breath = (sin(t * 2 * .pi / 3.0) + 1) / 2          // 0..1
            let outerAngle = (t * 360 / 22).truncatingRemainder(dividingBy: 360)
            let midAngle   = -(t * 360 / 14).truncatingRemainder(dividingBy: 360)
            let innerAngle = (t * 360 / 30).truncatingRemainder(dividingBy: 360)

            ZStack {
                // Outer ring with orbiting cyan dot
                outerRing(angle: reduceMotion ? 0 : outerAngle)
                // Mid dashed ring counter-rotating
                midRing(angle: reduceMotion ? 0 : midAngle)
                // Inner tick ring
                innerTickRing(angle: reduceMotion ? 0 : innerAngle)
                // Glow core
                core(breath: reduceMotion ? 0.5 : breath)
                if let icon {
                    icon
                        .frame(width: diameter * 0.20, height: diameter * 0.20)
                }
            }
            .frame(width: diameter, height: diameter)
        }
    }

    // MARK: - Sub-shapes

    private func outerRing(angle: Double) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.18), lineWidth: 1)
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.9), radius: 6)
                .offset(y: -diameter / 2 + 3)
        }
        .frame(width: diameter, height: diameter)
        .rotationEffect(.degrees(angle))
    }

    private func midRing(angle: Double) -> some View {
        Circle()
            .stroke(color.opacity(0.28),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
            .frame(width: diameter - 56, height: diameter - 56)
            .rotationEffect(.degrees(angle))
    }

    private func innerTickRing(angle: Double) -> some View {
        let r = (diameter - 100) / 2
        return Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2
            ctx.stroke(
                Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
                with: .color(color.opacity(0.35)),
                lineWidth: 1
            )
            for i in 0..<36 {
                let a = Double(i) * 10 * .pi / 180
                let inner = (i % 3 == 0) ? r - 8 : r - 4
                let outer = r - 1
                let x1 = cx + inner * cos(a - .pi / 2)
                let y1 = cy + inner * sin(a - .pi / 2)
                let x2 = cx + outer * cos(a - .pi / 2)
                let y2 = cy + outer * sin(a - .pi / 2)
                var p = Path()
                p.move(to: CGPoint(x: x1, y: y1))
                p.addLine(to: CGPoint(x: x2, y: y2))
                ctx.stroke(p, with: .color(color.opacity(0.5)), lineWidth: 1)
            }
        }
        .frame(width: diameter - 100, height: diameter - 100)
        .rotationEffect(.degrees(angle))
    }

    private func core(breath: Double) -> some View {
        let coreSize = diameter * 0.4

        let coreGradient: RadialGradient = {
            if tierMode {
                return RadialGradient(
                    colors: [
                        Color.white.opacity(0.95),
                        color.opacity(0.85),
                        color.opacity(0.55),
                        color.opacity(0.25)
                    ],
                    center: UnitPoint(x: 0.35, y: 0.30),
                    startRadius: 0,
                    endRadius: coreSize / 1.4
                )
            } else {
                return RadialGradient(
                    colors: [
                        Color.white.opacity(0.95),
                        SYN.cyan.opacity(0.85),
                        Color(hex: 0x0096B4, alpha: 0.6),
                        Color(hex: 0x005064, alpha: 0.3)
                    ],
                    center: UnitPoint(x: 0.35, y: 0.30),
                    startRadius: 0,
                    endRadius: coreSize / 1.4
                )
            }
        }()

        return ZStack {
            Circle()
                .fill(coreGradient)
                .frame(width: coreSize, height: coreSize)
                .shadow(color: color.opacity(0.7 + 0.2 * breath),
                        radius: 60 + 20 * breath)
                .shadow(color: color.opacity(0.4 + 0.15 * breath),
                        radius: 120 + 40 * breath)

            // Inner highlight
            Ellipse()
                .fill(Color.white.opacity(0.55))
                .frame(width: coreSize * 0.32, height: coreSize * 0.24)
                .offset(x: -coreSize * 0.18, y: -coreSize * 0.20)
                .blur(radius: 6)
                .frame(width: coreSize, height: coreSize)
                .mask(Circle().frame(width: coreSize, height: coreSize))
        }
    }
}
