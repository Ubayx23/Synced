import SwiftUI

struct InsightCard: Identifiable {
    let id = UUID()
    let headline: String
    let supportingStat: String
    let sessionCount: Int
    let sentiment: InsightSentiment
    let icon: String
}

enum InsightSentiment {
    case positive, warning, negative, neutral

    var accent: Color {
        switch self {
        case .positive: return SYN.green
        case .warning:  return SYN.amber
        case .negative: return SYN.red
        case .neutral:  return SYN.textDim
        }
    }
}

struct InsightCardView: View {
    let card: InsightCard

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Image(systemName: card.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(card.sentiment.accent)

                Spacer()

                confidencePill
            }

            Spacer().frame(height: 8)

            Text(card.headline)
                .font(.synDisplay(16, weight: .semibold))
                .foregroundStyle(SYN.text)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 6)

            Text(card.supportingStat)
                .font(.synText(13))
                .foregroundStyle(SYN.textDim)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(SYN.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var borderColor: Color {
        if case .neutral = card.sentiment { return SYN.border }
        return card.sentiment.accent.opacity(0.40)
    }

    @ViewBuilder
    private var confidencePill: some View {
        if card.sessionCount < 5 {
            pillLabel(text: "Early data", color: SYN.amber)
        } else {
            pillLabel(text: "Based on \(card.sessionCount) sessions",
                      color: SYN.textFaint)
        }
    }

    private func pillLabel(text: String, color: Color) -> some View {
        Text(text)
            .font(.synText(11))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 999)
                    .fill(SYN.surfaceHi)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(SYN.border, lineWidth: 1)
            )
    }
}
