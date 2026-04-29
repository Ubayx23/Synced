import SwiftUI

struct S6Benefits: View {
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var phase = 0

    private let items: [String] = [
        "What sleep amount fuels your heaviest lifts",
        "Which meal timing wrecks your sessions",
        "Your true recovery score, weekly",
        "Where you rank in your gym group",
        "Your tier each Sunday at midnight"
    ]

    var body: some View {
        ScreenShell(progress: ScreenProgress.s6, onBack: onBack) {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowTag(text: "Week 2 unlocks")
                    .phaseFadeUp(phase: phase, delay: 0.05)

                Spacer().frame(height: 18)

                (Text("In two weeks, ")
                    .foregroundColor(.white)
                 + Text("you'll know")
                    .foregroundColor(SYN.cyan))
                    .font(.synDisplay(30, weight: .bold))
                    .kerning(-0.9)
                    .lineSpacing(2)
                    .shadow(color: SYN.cyan.opacity(0.25), radius: 12)
                    .phaseFadeUp(phase: phase, delay: 0.18)

                Spacer().frame(height: 28)

                VStack(spacing: 10) {
                    ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                        benefitRow(item)
                            .phaseSlideLeft(phase: phase, delay: 0.36 + Double(idx) * 0.08)
                    }
                }

                Spacer()
            }
        } cta: {
            PrimaryButton(title: "Continue", action: onNext)
        }
        .task { withAnimation { phase = 1 } }
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(SYN.cyan.opacity(0.18))
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(SYN.cyan.opacity(0.5), lineWidth: 1))
                    .shadow(color: SYN.cyan.opacity(0.55), radius: 8)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SYN.cyan)
            }
            Text(text)
                .font(.synText(15))
                .foregroundStyle(SYN.text)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(LinearGradient(colors: [Color(hex: 0x18181B), Color(hex: 0x131316)],
                                     startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            HStack(spacing: 0) {
                Rectangle().fill(SYN.cyan).frame(width: 2)
                Spacer()
            }.clipShape(RoundedRectangle(cornerRadius: Radius.card))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card).stroke(SYN.border, lineWidth: 1)
        )
    }
}
