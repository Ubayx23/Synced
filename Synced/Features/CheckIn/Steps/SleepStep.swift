import SwiftUI

struct SleepStep: View {
    @Binding var sleepHours: Double
    @Binding var sleepQuality: Int

    private struct QualityOption: Identifiable {
        let v: Int
        let icon: String
        let iconColor: Color
        let title: String
        let subtitle: String
        var id: Int { v }
    }

    private static let qualityOptions: [QualityOption] = [
        .init(v: 1, icon: "moon.zzz.fill", iconColor: SYN.textFaint, title: "Terrible", subtitle: "Barely slept"),
        .init(v: 2, icon: "moon.fill",     iconColor: SYN.textDim,   title: "Poor",     subtitle: "Slept but not well"),
        .init(v: 3, icon: "cloud.fill",    iconColor: SYN.textDim,   title: "Okay",     subtitle: "Average night"),
        .init(v: 4, icon: "sun.max.fill",  iconColor: SYN.amber,     title: "Good",     subtitle: "Slept well"),
        .init(v: 5, icon: "sun.max.fill",  iconColor: SYN.cyan,      title: "Great",    subtitle: "Fully rested"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowText(text: "Step 1 of 3")
                    .foregroundStyle(SYN.textFaint)

                Spacer().frame(height: 24)

                Text("How did you sleep?")
                    .font(.synDisplay(28, weight: .bold))
                    .foregroundStyle(SYN.text)

                Spacer().frame(height: 8)

                Text("Hours and quality matter equally.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)

                Spacer().frame(height: 48)

                hoursSection

                Spacer().frame(height: 32)

                divider

                Spacer().frame(height: 24)

                EyebrowText(text: "How rested do you feel?")
                    .foregroundStyle(SYN.textFaint)

                Spacer().frame(height: 16)

                qualityCards

                Color.clear.frame(height: 32)
            }
            .padding(.horizontal, Spacing.pageH)
        }
    }

    // MARK: - Hours section

    private var hoursSection: some View {
        VStack(spacing: 0) {
            Text(String(format: "%.1f", sleepHours))
                .font(.synDisplay(80, weight: .bold))
                .foregroundStyle(SYN.text)
                .shadow(color: SYN.cyan.opacity(0.15), radius: 20)

            Spacer().frame(height: 4)

            EyebrowText(text: "Hours slept")
                .foregroundStyle(SYN.textDim)

            Spacer().frame(height: 24)

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
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(SYN.border)
            .frame(height: 1)
            .padding(.horizontal, 24)
    }

    // MARK: - Quality cards

    private var qualityCards: some View {
        VStack(spacing: 8) {
            ForEach(Self.qualityOptions) { opt in
                CheckInOptionCard(
                    icon: opt.icon,
                    iconColor: opt.iconColor,
                    title: opt.title,
                    subtitle: opt.subtitle,
                    isSelected: sleepQuality == opt.v,
                    action: {
                        withAnimation(.spring(response: 0.3)) { sleepQuality = opt.v }
                    }
                )
            }
        }
    }
}
