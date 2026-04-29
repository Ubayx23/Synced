import SwiftUI

struct MealTypeStep: View {
    @Binding var value: String

    private struct Option: Identifiable {
        let icon: String
        let iconColor: Color
        let title: String
        let subtitle: String
        var id: String { title }
    }

    private static let options: [Option] = [
        .init(icon: "leaf.fill",          iconColor: SYN.green,     title: "Clean meal",   subtitle: "Whole foods, protein heavy"),
        .init(icon: "fork.knife",         iconColor: SYN.textDim,   title: "Regular meal", subtitle: "Balanced, nothing special"),
        .init(icon: "flame.fill",         iconColor: SYN.amber,     title: "Light snack",  subtitle: "Something small"),
        .init(icon: "xmark.circle.fill",  iconColor: SYN.red,       title: "Junk food",    subtitle: "Fast food, processed"),
        .init(icon: "nosign",             iconColor: SYN.textFaint, title: "Nothing yet",  subtitle: "Haven't eaten today"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "Step 3 of 5")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 24)

            Text("What did you last eat?")
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)

            Spacer().frame(height: 8)

            Text("Most recent meal or snack")
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
