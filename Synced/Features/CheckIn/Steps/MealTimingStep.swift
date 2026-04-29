import SwiftUI

struct MealTimingStep: View {
    @Binding var value: String
    let mealType: String

    private struct Option: Identifiable {
        let icon: String
        let iconColor: Color
        let title: String
        let subtitle: String
        var id: String { title }
    }

    private static let options: [Option] = [
        .init(icon: "clock.fill", iconColor: SYN.red,       title: "Under 1 hour",    subtitle: "Still digesting"),
        .init(icon: "clock.fill", iconColor: SYN.amber,     title: "1 to 2 hours",    subtitle: "Getting there"),
        .init(icon: "clock.fill", iconColor: SYN.cyan,      title: "2 to 3 hours",    subtitle: "Sweet spot"),
        .init(icon: "clock.fill", iconColor: SYN.green,     title: "3 or more hours", subtitle: "Fully digested"),
        .init(icon: "nosign",     iconColor: SYN.textFaint, title: "Haven't eaten",   subtitle: "Skipping today"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "Step 4 of 5")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 24)

            Text("How long ago did you eat?")
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)

            Spacer().frame(height: 8)

            Text("Approximate is fine")
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
                        isSelected: value == opt.title,
                        action: {
                            withAnimation(.spring(response: 0.3)) { value = opt.title }
                        }
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.pageH)
    }
}
