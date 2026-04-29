import SwiftUI

struct SleepQualityStep: View {
    @Binding var value: Int

    private struct Option: Identifiable {
        let v: Int
        let icon: String
        let iconColor: Color
        let title: String
        let subtitle: String
        var id: Int { v }
    }

    private static let options: [Option] = [
        .init(v: 1, icon: "moon.zzz.fill", iconColor: SYN.textFaint, title: "Terrible", subtitle: "Barely slept"),
        .init(v: 2, icon: "moon.fill",     iconColor: SYN.textDim,   title: "Poor",     subtitle: "Slept but not well"),
        .init(v: 3, icon: "cloud.fill",    iconColor: SYN.textDim,   title: "Okay",     subtitle: "Average night"),
        .init(v: 4, icon: "sun.max.fill",  iconColor: SYN.amber,     title: "Good",     subtitle: "Slept well"),
        .init(v: 5, icon: "sun.max.fill",  iconColor: SYN.cyan,      title: "Great",    subtitle: "Fully rested"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "Step 2 of 5")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 24)

            Text("How rested do you feel?")
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)

            Spacer().frame(height: 8)

            Text("Be honest")
                .font(.synText(15))
                .foregroundStyle(SYN.textDim)

            Spacer().frame(height: 32)

            VStack(spacing: 10) {
                ForEach(Self.options) { opt in
                    CheckInOptionCard(
                        icon: opt.icon,
                        iconColor: opt.iconColor,
                        title: opt.title,
                        subtitle: opt.subtitle,
                        isSelected: value == opt.v,
                        action: {
                            withAnimation(.spring(response: 0.3)) { value = opt.v }
                        }
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.pageH)
    }
}
