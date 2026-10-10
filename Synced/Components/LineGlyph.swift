import SwiftUI

/// Small line icons drawn on a 24 x 24 grid with a 1.6 stroke, round caps
/// and joins, matching the "Today Final" mockup. Colored by the current
/// foreground style.
struct LineGlyph: View {
    enum Kind {
        /// Ring with a center dot: the Today tab.
        case today
        /// Three ascending bars: the Progress tab.
        case progress
        /// Right chevron on cards.
        case chevron
        /// Mountain outline: climb sessions.
        case mountain
    }

    let kind: Kind
    var size: CGFloat = 24

    var body: some View {
        Canvas { context, canvas in
            let s = canvas.width / 24
            let style = StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
            func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: (cx - r) * s, y: (cy - r) * s, width: 2 * r * s, height: 2 * r * s))
            }
            func line(_ points: [CGPoint]) -> Path {
                var path = Path()
                path.addLines(points)
                return path
            }

            switch kind {
            case .today:
                context.stroke(circle(12, 12, 8), with: .foreground, style: style)
                // The mockup's dot is filled and stroked, so it reads 2.8 wide.
                context.fill(circle(12, 12, 2.8), with: .foreground)
            case .progress:
                var bars = Path()
                for (x, top) in [(6.0, 14.0), (12.0, 10.0), (18.0, 5.0)] {
                    bars.move(to: pt(x, 19))
                    bars.addLine(to: pt(x, top))
                }
                context.stroke(bars, with: .foreground, style: style)
            case .chevron:
                context.stroke(line([pt(9, 5), pt(16, 12), pt(9, 19)]), with: .foreground, style: style)
            case .mountain:
                context.stroke(
                    line([pt(3, 19), pt(9, 9), pt(13, 14), pt(16, 10), pt(21, 19), pt(3, 19)]),
                    with: .foreground,
                    style: style
                )
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
