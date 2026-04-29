import SwiftUI

struct SelectableCard: View {
    let title: String
    var subtitle: String? = nil
    var leading: AnyView? = nil
    var trailing: AnyView? = nil
    var height: CGFloat = 80
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if let leading { leading }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.synText(17, weight: .semibold))
                        .foregroundStyle(SYN.text)
                    if let subtitle {
                        Text(subtitle)
                            .font(.synText(13))
                            .foregroundStyle(SYN.textDim)
                    }
                }
                Spacer(minLength: 0)
                if let trailing { trailing }
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(SYN.cyan)
                        .shadow(color: SYN.cyan.opacity(0.7), radius: 8)
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x1A1A1E), Color(hex: 0x131316)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(selected ? Color.white : SYN.border,
                            lineWidth: selected ? 1 : 1)
            )
            .shadow(color: selected ? SYN.cyan.opacity(0.45) : .black.opacity(0.35),
                    radius: selected ? 18 : 8,
                    y: selected ? 0 : 4)
            .contentShape(RoundedRectangle(cornerRadius: Radius.card))
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.18), value: selected)
    }
}
