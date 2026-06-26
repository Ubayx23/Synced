import SwiftUI

struct S8Frequency: View {
    var model: OnboardingModel
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var phase = 0
    @State private var days: Double = 4

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    private var count: Int { Int(days) }

    // Which days of a typical week fill in at a given frequency. Mirrors how a
    // hybrid athlete tends to spread lifting sessions across the week.
    private func litDays(_ n: Int) -> Set<Int> {
        switch n {
        case 1:  return [2]                 // Wed
        case 2:  return [0, 3]              // Mon, Thu
        case 3:  return [0, 2, 4]           // Mon, Wed, Fri
        case 4:  return [0, 1, 3, 4]        // Mon, Tue, Thu, Fri
        case 5:  return [0, 1, 2, 3, 4]     // Mon to Fri
        case 6:  return [0, 1, 2, 3, 4, 5]  // Mon to Sat
        default: return [0, 1, 2, 3, 4, 5, 6]
        }
    }

    var body: some View {
        ScreenShell(progress: ScreenProgress.s4, onBack: onBack, ambient: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("How many days will you show up?")
                    .font(.synDisplay(28, weight: .bold))
                    .foregroundStyle(SYN.text)
                    .kerning(-0.9)
                    .lineSpacing(2)
                    .shadow(color: SYN.cyan.opacity(0.25), radius: 12)
                    .phaseFadeUp(phase: phase, delay: 0.18)

                Spacer()

                weekVisual
                    .phaseFadeUp(phase: phase, delay: 0.34)

                Spacer().frame(height: 22)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(count)")
                        .font(.synMono(40, weight: .bold))
                        .foregroundStyle(SYN.text)
                        .contentTransition(.numericText())
                    Text("days a week")
                        .font(.synText(15))
                        .foregroundStyle(SYN.textDim)
                }
                .phaseFadeUp(phase: phase, delay: 0.40)

                Spacer().frame(height: 10)

                Text("Most lifters who climb train 3 to 4 days a week.")
                    .font(.synText(13))
                    .foregroundStyle(SYN.textFaint)
                    .phaseFadeUp(phase: phase, delay: 0.46)

                Spacer()

                SpecSlider(
                    value: $days,
                    range: 1...7,
                    step: 1,
                    ticks: [1, 2, 3, 4, 5, 6, 7],
                    tickLabels: ["1", "2", "3", "4", "5", "6", "7"]
                )
                .phaseFadeUp(phase: phase, delay: 0.52)

                Spacer().frame(height: 16)
            }
        } cta: {
            PrimaryButton(title: "Continue") {
                model.daysPerWeek = count
                UserDefaults.standard.set(count, forKey: "trainingFrequency")
                onNext()
            }
        }
        .onAppear { days = Double(model.daysPerWeek) }
        .task { withAnimation { phase = 1 } }
    }

    // The hero: a mock week where the planned lifting days light up in cyan as
    // the slider moves. Matches the calendar day-cell language used elsewhere.
    private var weekVisual: some View {
        let lit = litDays(count)
        return HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { idx in
                dayCell(idx, isLit: lit.contains(idx))
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.3, dampingFraction: 0.72), value: count)
    }

    private func dayCell(_ idx: Int, isLit: Bool) -> some View {
        VStack(spacing: 6) {
            Text(dayLabels[idx])
                .font(.synText(11, weight: .semibold))
                .foregroundStyle(isLit ? SYN.cyan : SYN.textFaint)
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isLit ? SYN.cyan.opacity(0.12) : SYN.surface)
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isLit ? SYN.cyan : SYN.border, lineWidth: isLit ? 1.5 : 1)
                if isLit {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SYN.cyan)
                }
            }
            .frame(height: 48)
            .shadow(color: isLit ? SYN.cyan.opacity(0.3) : .clear, radius: 5)
        }
    }
}
