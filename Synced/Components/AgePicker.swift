import SwiftUI

/// Five-row age picker: shows -2/-1/selected/+1/+2 with opacity falloff.
/// Drag to scroll, tap a neighbor to jump ±1 / ±2.
struct AgePicker: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 13...90

    @GestureState private var drag: CGFloat = 0
    private let rowHeight: CGFloat = 56

    var body: some View {
        let visible: [Int] = (-2...2).map { value + $0 }

        VStack(spacing: 0) {
            ForEach(visible, id: \.self) { age in
                let offset = age - value
                row(age: age, offset: offset)
                    .frame(height: rowHeight)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if range.contains(age) {
                            withAnimation(.easeOut(duration: 0.22)) { value = age }
                        }
                    }
            }
        }
        .frame(height: rowHeight * 5)
        .frame(maxWidth: .infinity)
        .mask(
            LinearGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.22),
                .init(color: .black, location: 0.78),
                .init(color: .clear, location: 1)
            ], startPoint: .top, endPoint: .bottom)
        )
        .gesture(
            DragGesture()
                .updating($drag) { g, state, _ in state = g.translation.height }
                .onEnded { g in
                    let delta = -Int((g.translation.height / rowHeight).rounded())
                    let next = max(range.lowerBound, min(range.upperBound, value + delta))
                    withAnimation(.easeOut(duration: 0.28)) { value = next }
                }
        )
    }

    @ViewBuilder
    private func row(age: Int, offset: Int) -> some View {
        let isSelected = offset == 0
        let opacity: Double = {
            switch abs(offset) {
            case 0:  return 1.0
            case 1:  return 0.45
            default: return 0.20
            }
        }()
        let valid = range.contains(age)

        HStack(spacing: 8) {
            Spacer()
            Text(valid ? "\(age)" : "")
                .font(.synMono(isSelected ? 80 : 28, weight: isSelected ? .bold : .medium))
                .foregroundStyle(SYN.text)
                .shadow(color: isSelected ? SYN.cyan.opacity(0.55) : .clear, radius: 24)
                .shadow(color: isSelected ? SYN.cyan.opacity(0.35) : .clear, radius: 60)
                .opacity(opacity)
            if isSelected {
                Text("yrs")
                    .font(.synMono(14, weight: .medium))
                    .foregroundStyle(SYN.textFaint)
                    .padding(.bottom, 12)
            }
            Spacer()
        }
    }
}
