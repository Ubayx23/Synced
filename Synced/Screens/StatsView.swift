import SwiftUI
import Charts

private struct SessionDot: Identifiable {
    let id = UUID()
    let day: Int
    let rating: Double
}

private let mockInsights: [InsightCard] = [
    InsightCard(
        headline: "You lift best after 7.5+ hours of sleep",
        supportingStat: "Avg rating 4.3 with 7.5h+ vs 2.8 with less",
        sessionCount: 14,
        sentiment: .positive,
        icon: "moon.stars.fill"
    ),
    InsightCard(
        headline: "Rice cakes before lifting hurts your sessions",
        supportingStat: "3 of your 4 lowest-rated sessions included this meal",
        sessionCount: 8,
        sentiment: .negative,
        icon: "exclamationmark.triangle.fill"
    ),
    InsightCard(
        headline: "Sweet spot is lifting 2 to 3 hours after eating",
        supportingStat: "Avg rating 4.1 in this window vs 2.9 under 1 hour",
        sessionCount: 12,
        sentiment: .positive,
        icon: "clock.fill"
    ),
    InsightCard(
        headline: "Chicken and rice before lifting is your best meal",
        supportingStat: "Avg rating 4.6 on sessions with this meal",
        sessionCount: 6,
        sentiment: .positive,
        icon: "fork.knife"
    ),
    InsightCard(
        headline: "Pre-workout does not improve your sessions",
        supportingStat: "Avg rating 3.1 with vs 3.8 without pre-workout",
        sessionCount: 9,
        sentiment: .warning,
        icon: "bolt.slash.fill"
    ),
    InsightCard(
        headline: "Your Tuesday and Thursday sessions are strongest",
        supportingStat: "Avg rating 4.2 on these days vs 3.0 on others",
        sessionCount: 16,
        sentiment: .positive,
        icon: "calendar.badge.checkmark"
    ),
]

private let mockSessionDots: [SessionDot] = [
    SessionDot(day: 1,  rating: 3.0),
    SessionDot(day: 3,  rating: 4.0),
    SessionDot(day: 5,  rating: 2.0),
    SessionDot(day: 7,  rating: 4.0),
    SessionDot(day: 9,  rating: 5.0),
    SessionDot(day: 11, rating: 3.0),
    SessionDot(day: 13, rating: 4.0),
    SessionDot(day: 15, rating: 5.0),
    SessionDot(day: 17, rating: 2.0),
    SessionDot(day: 19, rating: 4.0),
    SessionDot(day: 21, rating: 3.0),
    SessionDot(day: 23, rating: 5.0),
    SessionDot(day: 25, rating: 4.0),
    SessionDot(day: 27, rating: 4.0),
    SessionDot(day: 29, rating: 5.0),
]

struct StatsView: View {
    var body: some View {
        ZStack {
            SYN.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 16)

                    Spacer().frame(height: 24)

                    insightsFeed

                    Spacer().frame(height: 32)

                    EyebrowText(text: "Session history")
                        .foregroundStyle(SYN.textFaint)

                    Spacer().frame(height: 8)

                    Text("Last 30 days")
                        .font(.synText(13))
                        .foregroundStyle(SYN.textFaint)

                    Spacer().frame(height: 16)

                    chart

                    Spacer().frame(height: 24)

                    EyebrowText(text: "Your averages")
                        .foregroundStyle(SYN.textFaint)

                    Spacer().frame(height: 16)

                    averagesRow

                    Color.clear.frame(height: 32)
                }
                .padding(.horizontal, Spacing.pageH)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Insights")
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)
            Text("Based on 15 sessions")
                .font(.synText(14))
                .foregroundStyle(SYN.textDim)
        }
    }

    // MARK: - Insights

    private var insightsFeed: some View {
        VStack(spacing: 12) {
            ForEach(mockInsights) { card in
                InsightCardView(card: card)
            }
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart(mockSessionDots) { dot in
            LineMark(
                x: .value("Day", dot.day),
                y: .value("Rating", dot.rating)
            )
            .foregroundStyle(SYN.cyan.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Day", dot.day),
                y: .value("Rating", dot.rating)
            )
            .foregroundStyle(colorForRating(dot.rating))
            .symbolSize(120)
        }
        .chartYScale(domain: 1...5)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                AxisGridLine()
                    .foregroundStyle(SYN.border)
                AxisValueLabel {
                    if let v = value.as(Int.self) {
                        Text("\(v)")
                            .font(.system(size: 11))
                            .foregroundColor(SYN.textFaint)
                    }
                }
            }
        }
        .frame(height: 180)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(SYN.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SYN.border, lineWidth: 1)
        )
    }

    private func colorForRating(_ rating: Double) -> Color {
        switch rating {
        case 5: return SYN.cyan
        case 4: return SYN.green
        case 3: return SYN.text
        case 2: return SYN.amber
        default: return SYN.red
        }
    }

    // MARK: - Averages

    private var averagesRow: some View {
        HStack(spacing: 12) {
            AveragePill(value: "7.4",  valueColor: SYN.text, label: "avg sleep")
            AveragePill(value: "3.8",  valueColor: SYN.cyan, label: "avg rating")
            AveragePill(value: "2.3h", valueColor: SYN.text, label: "avg gap")
        }
    }
}

private struct AveragePill: View {
    let value: String
    let valueColor: Color
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.synMono(20, weight: .bold))
                .foregroundStyle(valueColor)
            Text(label)
                .font(.synText(11))
                .foregroundStyle(SYN.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SYN.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SYN.border, lineWidth: 1)
        )
    }
}

#Preview {
    StatsView()
        .preferredColorScheme(.dark)
}
