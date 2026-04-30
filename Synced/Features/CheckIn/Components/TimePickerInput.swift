import SwiftUI

/// Custom AM/PM time picker. Hours wrap 1-12 within the current half-day;
/// minutes toggle between :00 and :30. Numbers and chevrons match the
/// design language of the score card and energy step.
struct TimePickerInput: View {
    @Binding var selectedTime: Date

    @State private var hour: Int = 12
    @State private var minute: Int = 0
    @State private var isPM: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center, spacing: 0) {
                Spacer()
                column(
                    value: hour == 0 ? "12" : "\(hour)",
                    onUp: hourUp,
                    onDown: hourDown
                )
                VStack(spacing: 10) {
                    Circle()
                        .fill(SYN.textDim)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(SYN.textDim)
                        .frame(width: 8, height: 8)
                }
                .frame(width: 20)
                .offset(y: -4)
                column(
                    value: String(format: "%02d", minute),
                    onUp: minuteUp,
                    onDown: minuteDown
                )
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(SYN.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(SYN.border, lineWidth: 1)
            )

            amPmToggle
        }
        .frame(maxWidth: .infinity)
        .onAppear { syncFromBinding(writeBack: true) }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func column(value: String, onUp: @escaping () -> Void, onDown: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            ChevronButton(systemName: "chevron.up", action: onUp)
            Text(value)
                .font(.system(size: 72, weight: .bold, design: .default))
                .monospacedDigit()
                .foregroundStyle(SYN.text)
                .frame(width: 110)
                .shadow(color: SYN.cyan.opacity(0.12), radius: 16)
                .transaction { $0.animation = nil }
            ChevronButton(systemName: "chevron.down", action: onDown)
        }
    }

    private var amPmToggle: some View {
        HStack(spacing: 6) {
            segment(label: "AM", active: !isPM) { setIsPM(false) }
            segment(label: "PM", active: isPM)  { setIsPM(true) }
        }
        .padding(4)
        .frame(width: 160, height: 44)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(SYN.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(SYN.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func segment(label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.synText(15, weight: .semibold))
                .foregroundStyle(active ? Color.black : SYN.textFaint)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(active ? SYN.cyan : Color.clear)
                )
                .shadow(color: active ? SYN.cyan.opacity(0.4) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions (mutate state, then write back)

    private func hourUp() {
        hour = hour >= 12 ? 1 : hour + 1
        writeBack()
    }

    private func hourDown() {
        hour = hour <= 1 ? 12 : hour - 1
        writeBack()
    }

    private func minuteUp() {
        minute = minute >= 59 ? 0 : minute + 1
        writeBack()
    }

    private func minuteDown() {
        minute = minute <= 0 ? 59 : minute - 1
        writeBack()
    }

    private func setIsPM(_ newValue: Bool) {
        guard isPM != newValue else { return }
        withAnimation(.easeInOut(duration: 0.15)) { isPM = newValue }
        writeBack()
    }

    // MARK: - Date sync

    private func syncFromBinding(writeBack: Bool) {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
        let h24 = comps.hour ?? 9
        isPM = h24 >= 12
        let h12 = h24 % 12 == 0 ? 12 : h24 % 12
        hour = h12
        minute = comps.minute ?? 0
        if writeBack { self.writeBack() }
    }

    private func writeBack() {
        let now = Date()
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: now)
        let h24: Int = {
            if isPM && hour != 12 { return hour + 12 }
            if !isPM && hour == 12 { return 0 }
            return hour
        }()
        var rebuilt = DateComponents()
        rebuilt.year = comps.year
        rebuilt.month = comps.month
        rebuilt.day = comps.day
        rebuilt.hour = h24
        rebuilt.minute = minute
        rebuilt.second = 0
        if let date = Calendar.current.date(from: rebuilt) {
            selectedTime = date
        }
    }
}

// MARK: - Chevron button

private struct ChevronButton: View {
    let systemName: String
    let action: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button {
            // Mutate number outside any animated transaction so the digit
            // updates instantly without a crossfade ghost behind it.
            action()
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                isPressed = false
            }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(SYN.textDim)
                .frame(width: 44, height: 44)
                .scaleEffect(isPressed ? 0.85 : 1.0)
                .animation(.spring(response: 0.2), value: isPressed)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
