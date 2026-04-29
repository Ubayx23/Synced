import SwiftUI

/// Selectable row used by SleepQuality / MealType / MealTiming steps.
struct CheckInOptionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(iconColor)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.synDisplay(16, weight: .semibold))
                        .foregroundStyle(SYN.text)
                    Text(subtitle)
                        .font(.synText(13))
                        .foregroundStyle(SYN.textFaint)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(SYN.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(isSelected ? SYN.cyan : SYN.border,
                            lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: isSelected ? SYN.cyan.opacity(0.25) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
    }
}
