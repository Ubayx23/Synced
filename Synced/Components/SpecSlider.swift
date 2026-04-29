import SwiftUI

/// Custom slider matching prototype: thin track, filled portion in cyan,
/// 32pt cyan thumb with glow ring, optional tick row underneath.
struct SpecSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double = 1
    var ticks: [Double]? = nil
    var tickLabels: [String]? = nil

    @GestureState private var dragging = false

    private let trackHeight: CGFloat = 4
    private let thumbSize: CGFloat = 32

    private var fraction: Double {
        let r = range.upperBound - range.lowerBound
        guard r > 0 else { return 0 }
        return (value - range.lowerBound) / r
    }

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(SYN.border)
                        .frame(height: trackHeight)

                    Capsule()
                        .fill(
                            LinearGradient(colors: [SYN.cyan, SYN.cyanSoft],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: max(0, CGFloat(fraction) * w), height: trackHeight)
                        .shadow(color: SYN.cyan.opacity(0.55), radius: 8)

                    Circle()
                        .fill(SYN.cyan)
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay(
                            Circle().stroke(SYN.bg, lineWidth: 4)
                        )
                        .shadow(color: SYN.cyan.opacity(0.7),
                                radius: dragging ? 18 : 12)
                        .position(
                            x: max(thumbSize / 2,
                                   min(w - thumbSize / 2, CGFloat(fraction) * w)),
                            y: geo.size.height / 2
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .updating($dragging) { _, state, _ in state = true }
                                .onChanged { gesture in
                                    let x = max(0, min(w, gesture.location.x))
                                    let raw = range.lowerBound +
                                        Double(x / w) * (range.upperBound - range.lowerBound)
                                    let snapped = (raw / step).rounded() * step
                                    value = max(range.lowerBound,
                                                min(range.upperBound, snapped))
                                }
                        )
                }
                .frame(height: max(thumbSize, 44))
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let x = max(0, min(w, gesture.location.x))
                            let raw = range.lowerBound +
                                Double(x / w) * (range.upperBound - range.lowerBound)
                            let snapped = (raw / step).rounded() * step
                            value = max(range.lowerBound,
                                        min(range.upperBound, snapped))
                        }
                )
            }
            .frame(height: 44)

            if let ticks {
                HStack(spacing: 0) {
                    ForEach(Array(ticks.enumerated()), id: \.offset) { idx, t in
                        let label = tickLabels?[safe: idx] ?? formatTick(t)
                        let active = abs(t - value) < step * 0.5
                        Text(label)
                            .font(.synMono(11, weight: .medium))
                            .foregroundStyle(active ? SYN.cyan : SYN.textFaint)
                            .shadow(color: active ? SYN.cyan.opacity(0.7) : .clear, radius: 6)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func formatTick(_ t: Double) -> String {
        if t == t.rounded() { return String(Int(t)) }
        return String(format: "%.1f", t)
    }
}

extension Array {
    fileprivate subscript(safe i: Int) -> Element? {
        indices.contains(i) ? self[i] : nil
    }
}
