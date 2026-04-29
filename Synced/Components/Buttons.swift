import SwiftUI

struct PrimaryButton: View {
    let title: String
    var disabled: Bool = false
    var action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: { if !disabled { action() } }) {
            Text(title)
                .font(.synText(16, weight: .semibold))
                .kerning(-0.16)
                .foregroundStyle(disabled ? Color.black.opacity(0.45) : Color(hex: 0x0A0A0A))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                        .fill(disabled ? SYN.cyan.opacity(0.18) : SYN.cyan)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                        .stroke(SYN.cyan.opacity(disabled ? 0 : 0.4), lineWidth: 1)
                )
                .shadow(color: disabled ? .clear : SYN.cyan.opacity(0.35), radius: 16, y: 8)
                .scaleEffect(pressed ? 0.985 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeOut(duration: 0.12)) { pressed = true } }
                .onEnded   { _ in withAnimation(.easeOut(duration: 0.12)) { pressed = false } }
        )
    }
}

struct SecondaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.synText(16, weight: .medium))
                .kerning(-0.16)
                .foregroundStyle(SYN.text)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                        .fill(Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                        .stroke(SYN.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct TextLinkButton: View {
    let title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.synText(15, weight: .medium))
                .foregroundStyle(SYN.textDim)
        }
        .buttonStyle(.plain)
    }
}
