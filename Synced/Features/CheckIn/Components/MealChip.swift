import SwiftUI

struct MealChip: View {
    let meal: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? SYN.cyan : SYN.textFaint)
                Text(meal)
                    .font(.synText(14, weight: .medium))
                    .foregroundStyle(isSelected ? SYN.text : SYN.textDim)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? SYN.surfaceHi : SYN.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? SYN.cyan : SYN.border,
                            lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: isSelected ? SYN.cyan.opacity(0.20) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }
}
