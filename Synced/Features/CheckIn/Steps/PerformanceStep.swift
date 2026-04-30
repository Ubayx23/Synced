import SwiftUI

struct PerformanceStep: View {
    @Binding var sessionRating: Int
    @Binding var performanceVsExpectation: String

    private struct ExpectationOption: Identifiable {
        let label: String
        let subtitle: String
        let icon: String
        let accent: Color
        var id: String { label }
    }

    private static let expectationOptions: [ExpectationOption] = [
        .init(label: "Better than expected", subtitle: "Surprised myself today", icon: "arrow.up.circle.fill",   accent: SYN.cyan),
        .init(label: "As expected",          subtitle: "Hit my usual numbers",   icon: "equal.circle.fill",      accent: SYN.textDim),
        .init(label: "Worse than expected",  subtitle: "Didn't hit my numbers",  icon: "arrow.down.circle.fill", accent: SYN.amber),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "Step 1 of 2")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 24)

            Text("How did it go?")
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)

            Spacer().frame(height: 8)

            Text("Rate your session honestly.")
                .font(.synText(15))
                .foregroundStyle(SYN.textDim)

            Spacer().frame(height: 48)

            ratingSection

            Spacer().frame(height: 40)

            divider

            Spacer().frame(height: 32)

            EyebrowText(text: "vs expectation")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 12)

            VStack(spacing: 10) {
                ForEach(Self.expectationOptions) { opt in
                    expectationCard(opt)
                }
            }

            Color.clear.frame(height: 32)
        }
        .padding(.horizontal, Spacing.pageH)
    }

    // MARK: - Rating

    private var ratingSection: some View {
        VStack(spacing: 0) {
            Text("SESSION RATING")
                .font(.synText(11, weight: .semibold))
                .tracking(0.88)
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 16)

            HStack(spacing: 16) {
                Spacer()
                ForEach(1...5, id: \.self) { n in
                    ratingCircle(n)
                }
                Spacer()
            }

            Spacer().frame(height: 12)

            Text(ratingLabel(sessionRating))
                .font(.synText(14, weight: .medium))
                .foregroundStyle(ratingColor(sessionRating))
                .frame(height: 18)
                .transaction { $0.animation = nil }
        }
    }

    @ViewBuilder
    private func ratingCircle(_ n: Int) -> some View {
        let isSelected = sessionRating == n
        let accent = ratingAccent(n)
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                sessionRating = n
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? accent : Color.clear)
                Circle()
                    .stroke(isSelected ? accent : SYN.border, lineWidth: 1.5)
                Text("\(n)")
                    .font(.synDisplay(24, weight: .bold))
                    .foregroundStyle(numberColor(n, isSelected: isSelected))
            }
            .frame(width: 56, height: 56)
            .shadow(color: isSelected ? accent.opacity(glowOpacity(n)) : .clear,
                    radius: glowRadius(n))
        }
        .buttonStyle(.plain)
    }

    private func ratingAccent(_ n: Int) -> Color {
        switch n {
        case 1: return SYN.red
        case 2: return SYN.amber
        case 3: return SYN.text
        case 4: return SYN.green
        default: return SYN.cyan
        }
    }

    private func numberColor(_ n: Int, isSelected: Bool) -> Color {
        guard isSelected else { return SYN.textDim }
        // Rating 1 (red fill) reads better with white; the rest get black.
        return n == 1 ? .white : .black
    }

    private func glowOpacity(_ n: Int) -> Double {
        switch n {
        case 1: return 0.30
        case 5: return 0.35
        default: return 0
        }
    }

    private func glowRadius(_ n: Int) -> CGFloat {
        switch n {
        case 1: return 12
        case 5: return 16
        default: return 0
        }
    }

    private func ratingLabel(_ n: Int) -> String {
        switch n {
        case 1: return "Rough session"
        case 2: return "Below average"
        case 3: return "Solid session"
        case 4: return "Strong session"
        case 5: return "Best session"
        default: return ""
        }
    }

    private func ratingColor(_ n: Int) -> Color {
        switch n {
        case 1: return SYN.red
        case 2: return SYN.amber
        case 3: return SYN.textDim
        case 4: return SYN.green
        case 5: return SYN.cyan
        default: return .clear
        }
    }

    // MARK: - Expectation

    @ViewBuilder
    private func expectationCard(_ opt: ExpectationOption) -> some View {
        let isSelected = performanceVsExpectation == opt.label
        Button {
            withAnimation(.spring(response: 0.3)) {
                performanceVsExpectation = opt.label
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: opt.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(opt.accent)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(opt.label)
                        .font(.synDisplay(16, weight: .semibold))
                        .foregroundStyle(SYN.text)
                    Text(opt.subtitle)
                        .font(.synText(13))
                        .foregroundStyle(SYN.textFaint)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? SYN.surfaceHi : SYN.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? opt.accent : SYN.border,
                            lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: isSelected ? opt.accent.opacity(0.25) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(SYN.border)
            .frame(height: 1)
            .padding(.horizontal, 24)
    }
}
