import SwiftUI

struct SHome: View {
    var model: OnboardingModel
    var onRestart: () -> Void

    var body: some View {
        ZStack {
            ScreenBackground()
            AmbientGlow()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 24)

                HStack {
                    SyncedWordmark(size: 22)
                    Spacer()
                    Text(model.resolvedTier.displayName.uppercased())
                        .font(.synText(11, weight: .semibold))
                        .tracking(2.0)
                        .foregroundStyle(model.resolvedTier.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .overlay(
                            Capsule().stroke(model.resolvedTier.color.opacity(0.55), lineWidth: 1)
                        )
                }
                .padding(.horizontal, Spacing.pageH)

                Spacer().frame(height: 24)

                Text("Hey \(model.firstName.isEmpty ? "Lifter" : model.firstName).")
                    .font(.synDisplay(34, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.pageH)

                Text("Tomorrow we'll start tracking. For now, soak in this moment.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)
                    .padding(.horizontal, Spacing.pageH)
                    .padding(.top, 6)

                Spacer().frame(height: 36)

                statBlock
                    .padding(.horizontal, Spacing.pageH)

                Spacer()

                SecondaryButton(title: "↺ Replay onboarding", action: onRestart)
                    .padding(.horizontal, Spacing.pageH)
                    .padding(.bottom, 48)
            }
        }
    }

    private var statBlock: some View {
        HStack(spacing: 12) {
            statCard(label: "Days / wk", value: "\(model.daysPerWeek)")
            statCard(label: "Sleep", value: sleepDisplay)
            statCard(label: "Goal", value: model.goal?.rawValue.split(separator: " ").first.map(String.init) ?? "—")
        }
    }

    private var sleepDisplay: String {
        let h = model.sleepHours
        if h == h.rounded() { return "\(Int(h))h" }
        return String(format: "%.1fh", h)
    }

    private func statCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.synText(10, weight: .semibold))
                .tracking(1.6)
                .foregroundStyle(SYN.textFaint)
            Text(value)
                .font(.synMono(22, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(LinearGradient(colors: [Color(hex: 0x18181B), Color(hex: 0x131316)],
                                     startPoint: .top, endPoint: .bottom))
        )
        .overlay(RoundedRectangle(cornerRadius: Radius.card).stroke(SYN.border, lineWidth: 1))
    }
}
