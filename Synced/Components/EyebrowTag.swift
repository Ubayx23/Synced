import SwiftUI

/// Small uppercase pill: cyan border, soft inner glow, used as a section eyebrow above headlines.
struct EyebrowTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.synText(11, weight: .semibold))
            .tracking(2.0)
            .textCase(.uppercase)
            .foregroundStyle(SYN.cyan)
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(
                Capsule().fill(SYN.cyan.opacity(0.06))
            )
            .overlay(
                Capsule().stroke(SYN.cyan.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: SYN.cyan.opacity(0.25), radius: 16)
    }
}
