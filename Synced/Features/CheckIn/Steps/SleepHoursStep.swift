import SwiftUI

struct SleepHoursStep: View {
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "Step 1 of 5")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 24)

            Text("How long did you sleep?")
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)

            Spacer().frame(height: 8)

            Text("Last night")
                .font(.synText(15))
                .foregroundStyle(SYN.textDim)

            Spacer().frame(height: 80)

            VStack(spacing: 8) {
                Text(String(format: "%.1f", value))
                    .font(.synMono(96, weight: .bold))
                    .foregroundStyle(SYN.text)
                    .shadow(color: SYN.cyan.opacity(0.15), radius: 20)
                EyebrowText(text: "Hours")
                    .foregroundStyle(SYN.textDim)
            }
            .frame(maxWidth: .infinity)

            Spacer().frame(height: 48)

            Slider(value: $value, in: 4.0...12.0, step: 0.5)
                .tint(SYN.cyan)
                .padding(.horizontal, 24)

            Spacer().frame(height: 12)

            HStack {
                Text("4h")
                Spacer()
                Text("12h")
            }
            .font(.synText(13))
            .foregroundStyle(SYN.textFaint)
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.horizontal, Spacing.pageH)
    }
}
