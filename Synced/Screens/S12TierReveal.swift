import SwiftUI

struct S12TierReveal: View {
    var model: OnboardingModel
    var onBack: () -> Void
    /// Called from the "Enter Synced" CTA. Caller flips
    /// `hasCompletedOnboarding` so `RootView` can swap to `MainTabView`.
    var onNext: () -> Void

    @State private var phase = 0

    private let tier: Tier = .active

    var body: some View {
        ScreenShell(progress: nil, onBack: onBack, ambient: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 8)

                LuminousOrb(
                    diameter: 200,
                    color: tier.color,
                    icon: AnyView(
                        Image(systemName: tier.iconSystemName)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: tier.color.opacity(0.8), radius: 12)
                    ),
                    tierMode: true
                )

                Spacer().frame(height: 24)

                EyebrowTag(text: "Based on your answers")
                    .phaseFadeUp(phase: phase, delay: 0.05)

                Spacer().frame(height: 12)

                Text("Your starting tier is")
                    .font(.synDisplay(22, weight: .medium))
                    .foregroundStyle(SYN.textDim)
                    .phaseFadeUp(phase: phase, delay: 0.14)

                Spacer().frame(height: 4)

                Text(tier.displayName)
                    .font(.synDisplay(40, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.25), radius: 14)
                    .phaseFadeUp(phase: phase, delay: 0.22)

                Spacer().frame(height: 6)

                Text("40 to 59 score range")
                    .font(.synMono(14))
                    .foregroundStyle(SYN.textFaint)
                    .phaseFadeUp(phase: phase, delay: 0.30)

                Spacer().frame(height: 20)

                explainerCard
                    .phaseFadeUp(phase: phase, delay: 0.40)

                Spacer().frame(height: 18)

                tierLadder
                    .phaseFadeUp(phase: phase, delay: 0.52)

                Spacer().frame(height: 12)

                Text("Tiers reset every Sunday at midnight.")
                    .font(.synText(12))
                    .foregroundStyle(SYN.textFaint)
                    .phaseFadeUp(phase: phase, delay: 0.62)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } cta: {
            PrimaryButton(title: "Enter Synced", action: onNext)
        }
        .task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            withAnimation(.easeOut(duration: 0.7)) { phase = 1 }
        }
    }

    // MARK: - Explainer

    private var explainerCard: some View {
        (Text("Active").bold().foregroundColor(.white)
         + Text(" means you're showing up. Hit 60+ this week to reach ")
            .foregroundColor(SYN.textDim)
         + Text("Dialed").bold().foregroundColor(.white)
         + Text(".").foregroundColor(SYN.textDim))
            .font(.synText(15))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(SYN.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(SYN.border, lineWidth: 1)
            )
    }

    // MARK: - Tier ladder

    private var tierLadder: some View {
        VStack(spacing: 8) {
            ForEach(Tier.allCases) { t in
                tierRow(t)
            }
        }
    }

    @ViewBuilder
    private func tierRow(_ t: Tier) -> some View {
        let isCurrent = (t == tier)
        HStack(spacing: 10) {
            tierDot(t)
            Text(t.displayName)
                .font(isCurrent ? .synDisplay(15, weight: .semibold) : .synText(13, weight: .medium))
                .foregroundStyle(isCurrent ? SYN.text : SYN.textDim)
            Spacer()
            Text("\(t.range.lowerBound) to \(t.range.upperBound)")
                .font(.synMono(13))
                .foregroundStyle(SYN.textFaint)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, isCurrent ? 8 : 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrent ? SYN.surfaceHi : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrent ? SYN.cyan.opacity(0.6) : .clear, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func tierDot(_ t: Tier) -> some View {
        if t == .synced {
            Circle()
                .fill(SYN.cyan)
                .frame(width: 10, height: 10)
                .shadow(color: SYN.cyan.opacity(0.6), radius: 4)
        } else if t == tier {
            Circle()
                .fill(SYN.text)
                .frame(width: 8, height: 8)
        } else {
            Circle()
                .fill(t.color)
                .frame(width: 8, height: 8)
        }
    }
}
