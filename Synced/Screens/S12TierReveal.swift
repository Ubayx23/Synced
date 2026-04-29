import SwiftUI

struct S12TierReveal: View {
    var model: OnboardingModel
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var phase = 0

    private var tier: Tier { model.resolvedTier }

    var body: some View {
        ScreenShell(progress: ScreenProgress.s12, onBack: onBack, ambient: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 12)

                LuminousOrb(
                    diameter: 220,
                    color: tier.color,
                    icon: AnyView(
                        Image(systemName: tier.iconSystemName)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: tier.color.opacity(0.8), radius: 12)
                    ),
                    tierMode: true
                )

                Spacer().frame(height: 32)

                EyebrowTag(text: "Your starting tier")
                    .phaseFadeUp(phase: phase, delay: 0.05)

                Spacer().frame(height: 14)

                tierName
                    .phaseFadeUp(phase: phase, delay: 0.18)

                Spacer().frame(height: 6)

                Text("Score range: \(tier.range.lowerBound)–\(tier.range.upperBound)")
                    .font(.synMono(13, weight: .medium))
                    .foregroundStyle(SYN.textFaint)
                    .phaseFadeUp(phase: phase, delay: 0.30)

                Spacer().frame(height: 22)

                explainerCard
                    .phaseFadeUp(phase: phase, delay: 0.42)

                Spacer()
            }
            .background(
                RadialGradient(
                    colors: [tier.color.opacity(0.22), tier.color.opacity(0.06), .clear],
                    center: UnitPoint(x: 0.5, y: 0.30),
                    startRadius: 0, endRadius: 420
                )
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
            )
        } cta: {
            PrimaryButton(title: "Enter Synced", action: onNext)
        }
        .task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            withAnimation(.easeOut(duration: 0.7)) { phase = 1 }
        }
    }

    @ViewBuilder
    private var tierName: some View {
        if tier == .synced {
            Text(tier.displayName)
                .font(.synDisplay(48, weight: .bold))
                .kerning(-1.4)
                .foregroundStyle(
                    LinearGradient(colors: [.white, SYN.cyan],
                                   startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: SYN.cyan.opacity(0.5), radius: 16)
        } else if tier == .active {
            Text(tier.displayName)
                .font(.synDisplay(48, weight: .bold))
                .kerning(-1.4)
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.25), radius: 14)
        } else {
            Text(tier.displayName)
                .font(.synDisplay(48, weight: .bold))
                .kerning(-1.4)
                .foregroundStyle(tier.color)
                .shadow(color: tier.color.opacity(0.55), radius: 14)
        }
    }

    private var explainerCard: some View {
        HStack(spacing: 0) {
            Rectangle().fill(tier.color).frame(width: 2)
                .shadow(color: tier.color.opacity(0.6), radius: 6)

            Text(tier.tagline)
                .font(.synText(15))
                .foregroundStyle(SYN.text)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(LinearGradient(colors: [Color(hex: 0x1A1A1E), Color(hex: 0x131316)],
                                     startPoint: .top, endPoint: .bottom))
        )
        .overlay(RoundedRectangle(cornerRadius: Radius.card).stroke(SYN.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }
}
