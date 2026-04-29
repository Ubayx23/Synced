import SwiftUI

struct EnergyLevelStep: View {
    @Binding var value: Double

    private static let labels: [Int: String] = [
        1:  "Running on empty",
        2:  "Pretty rough",
        3:  "Below average",
        4:  "Feeling slow",
        5:  "Neutral",
        6:  "Decent",
        7:  "Feeling good",
        8:  "Locked in",
        9:  "Firing on all cylinders",
        10: "Best day ever",
    ]

    private var intValue: Int { Int(value) }

    private var levelColor: Color {
        switch intValue {
        case 1...3: return SYN.red
        case 4...5: return SYN.amber
        case 6...7: return SYN.text
        case 8...9: return SYN.green
        default:    return SYN.cyan
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "Step 5 of 5")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 24)

            Text("How's your energy right now?")
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)

            Spacer().frame(height: 8)

            Text("Before you walk in")
                .font(.synText(15))
                .foregroundStyle(SYN.textDim)

            Spacer().frame(height: 80)

            VStack(spacing: 8) {
                Text("\(intValue)")
                    .font(.synMono(96, weight: .bold))
                    .foregroundStyle(levelColor)
                    .shadow(color: intValue == 10 ? SYN.cyan.opacity(0.5) : .clear, radius: 24)

                Text(Self.labels[intValue] ?? "")
                    .font(.synDisplay(17, weight: .semibold))
                    .foregroundStyle(levelColor)
            }
            .frame(maxWidth: .infinity)

            Spacer().frame(height: 48)

            Slider(value: $value, in: 1.0...10.0, step: 1)
                .tint(SYN.cyan)
                .padding(.horizontal, 24)

            Spacer().frame(height: 12)

            HStack {
                Text("1")
                Spacer()
                Text("10")
            }
            .font(.synText(13))
            .foregroundStyle(SYN.textFaint)
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.horizontal, Spacing.pageH)
    }
}
