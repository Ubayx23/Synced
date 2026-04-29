import SwiftUI

struct SleepStep: View {
    @Binding var sleepHours: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "Step 1 of 2")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 24)

            Text("How did you sleep?")
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)

            Spacer().frame(height: 8)

            Text("Last night's hours drive your score.")
                .font(.synText(15))
                .foregroundStyle(SYN.textDim)

            Spacer()

            VStack(spacing: 0) {
                Text(String(format: "%.1f", sleepHours))
                    .font(.synDisplay(80, weight: .bold))
                    .foregroundStyle(SYN.text)
                    .shadow(color: SYN.cyan.opacity(0.15), radius: 20)

                Spacer().frame(height: 4)

                EyebrowText(text: "Hours slept")
                    .foregroundStyle(SYN.textDim)

                Spacer().frame(height: 32)

                Slider(value: $sleepHours, in: 4.0...12.0, step: 0.5)
                    .tint(SYN.cyan)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 8)

                HStack {
                    Text("4h")
                    Spacer()
                    Text("12h")
                }
                .font(.synText(13))
                .foregroundStyle(SYN.textFaint)
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)

            Spacer()

            Color.clear.frame(height: 32)
        }
        .padding(.horizontal, Spacing.pageH)
    }
}
