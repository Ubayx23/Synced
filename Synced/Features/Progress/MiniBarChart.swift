import SwiftUI

/// Passive sparkline of recent top-set weights: one bar per session,
/// oldest to newest, heaviest at full height. Bars scale across the values'
/// own range (the lightest sits at about a third of the height), because
/// top sets cluster tightly and bars scaled from zero look flat. The newest
/// bar is full cyan ("you are here"); the rest are dimmer. No axes, labels,
/// or taps.
struct MiniBarChart: View {
    let values: [Double]
    let width: CGFloat
    var height: CGFloat = 24

    private let gap: CGFloat = 2
    private let minBarHeight: CGFloat = 3

    var body: some View {
        if !values.isEmpty {
            let high = values.max() ?? 0
            let low = values.min() ?? 0
            // Baseline half a range below the lightest value, so it lands
            // near a third of the height; equal values draw full height.
            let floor = max(0, low - (high - low) * 0.5)
            let barWidth = max((width - CGFloat(values.count - 1) * gap) / CGFloat(values.count), 1)
            HStack(alignment: .bottom, spacing: gap) {
                ForEach(values.indices, id: \.self) { index in
                    let fraction = high > floor ? (values[index] - floor) / (high - floor) : 1
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(index == values.count - 1 ? SYN.cyan : SYN.cyan.opacity(0.6))
                        .frame(width: barWidth, height: max(height * fraction, minBarHeight))
                }
            }
            .frame(width: width, height: height, alignment: values.count == 1 ? .bottom : .bottomLeading)
            .accessibilityHidden(true)
        }
    }
}
