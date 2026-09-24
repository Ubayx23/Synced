import Charts
import SwiftUI

/// Progress tab: climb grade trend, lift exercise trends, and a small
/// overall footer. Read-only; everything derives from one fetch.
struct ProgressScreen: View {
    @State private var store = ProgressStore()
    @State private var window: ProgressWindow = .last30
    @State private var showingProfile = false

    private var summary: ProgressSummary {
        ProgressSummary(sessions: store.sessions, window: window)
    }

    var body: some View {
        ZStack {
            ScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header

                    switch store.loadState {
                    case .loading where store.sessions.isEmpty:
                        SwiftUI.ProgressView()
                            .tint(SYN.textDim)
                            .frame(maxWidth: .infinity)
                            .padding(.top, Spacing.xxl)
                    case .failed(let message) where store.sessions.isEmpty:
                        failure(message)
                    default:
                        let summary = summary
                        if let hero = summary.hero {
                            heroView(hero)
                        }
                        climbSection(summary)
                        liftSection(summary)
                        overallSection(summary)
                    }
                }
                .padding(.horizontal, Spacing.pageH)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
                .animation(.easeOut(duration: 0.2), value: window)
            }
            .scrollIndicators(.hidden)
            .refreshable { await store.load() }
        }
        // Refetch every time the tab appears so sessions logged on Week show up.
        .onAppear { Task { await store.load() } }
        .sheet(isPresented: $showingProfile) {
            ProfileSheet()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                EyebrowText(text: "Your trends")
                    .foregroundStyle(SYN.textFaint)

                Spacer()

                // Same placement and hit target as the Week view's icon.
                Button { showingProfile = true } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(SYN.textDim)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, -Spacing.m)
                .padding(.trailing, -Spacing.m + 2)
                .accessibilityLabel("Profile")
            }

            Text("Progress")
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)
                .kerning(-0.6)

            Spacer().frame(height: Spacing.m)

            windowToggle
        }
    }

    private var windowToggle: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(ProgressWindow.allCases) { option in
                let selected = window == option
                Button { window = option } label: {
                    Text(option.title)
                        .font(.synText(13, weight: .semibold))
                        .foregroundStyle(selected ? SYN.bg : SYN.textDim)
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 32)
                        .background(Capsule().fill(selected ? SYN.cyan : .clear))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(Spacing.xs)
        .background(Capsule().fill(SYN.surface))
        .overlay(Capsule().stroke(SYN.border, lineWidth: 1))
    }

    private func failure(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.s) {
                Text("Couldn't load your progress.")
                    .font(.synText(13))
                    .foregroundStyle(SYN.red)
                Button("Retry") { Task { await store.load() } }
                    .font(.synText(13, weight: .semibold))
                    .foregroundStyle(SYN.cyan)
                    .buttonStyle(.plain)
            }
            #if DEBUG
            Text(message)
                .font(.synText(11))
                .foregroundStyle(SYN.textFaint)
                .lineLimit(2)
            #endif
        }
    }

    // MARK: - Hero

    private func heroView(_ hero: ProgressHero) -> some View {
        let headlineColor: Color = {
            switch hero.tone {
            case .dip:   return SYN.amber
            case .early: return SYN.textDim
            default:     return SYN.text
            }
        }()
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(hero.headline)
                .font(.synDisplay(22, weight: .bold))
                .foregroundStyle(headlineColor)
                .kerning(-0.4)
            Text(hero.support)
                .font(.synText(14))
                .foregroundStyle(SYN.textDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .contentTransition(.opacity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Climb

    @ViewBuilder
    private func climbSection(_ s: ProgressSummary) -> some View {
        section("Climb") {
            if let top = s.topGrade {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(s.window == .last30 ? "Highest grade this month" : "Highest grade ever")
                            .font(.synText(13))
                            .foregroundStyle(SYN.textDim)
                        Text("V\(top)")
                            .font(.synMono(44, weight: .semibold))
                            .foregroundStyle(SYN.cyan)
                            .shadow(color: SYN.cyan.opacity(0.35), radius: 14)
                            .contentTransition(.numericText())
                        if let comparison = s.comparison {
                            Text(comparison)
                                .font(.synText(13, weight: .medium))
                                .foregroundStyle(comparisonColor(comparison, downtrend: s.climbDowntrend))
                        }
                    }

                    GradePyramid(sendCounts: s.sendCounts)
                }
                .progressCard()
            } else if s.hasClimbedEver {
                Text(s.window == .last30 ? "No sends this month yet." : "No sends yet.")
                    .font(.synText(14))
                    .foregroundStyle(SYN.textDim)
                    .progressCard()
            } else {
                emptyState(
                    icon: SessionType.climb.symbol,
                    text: "Log a climb session to see your grade trend."
                )
            }
        }
    }

    /// Regression is information, not failure: amber, never red.
    private func comparisonColor(_ text: String, downtrend: Bool) -> Color {
        if downtrend || text.hasPrefix("-") { return SYN.amber }
        if text.hasPrefix("+") { return SYN.green }
        return SYN.textFaint
    }

    // MARK: - Lifts

    @ViewBuilder
    private func liftSection(_ s: ProgressSummary) -> some View {
        section("Lifts") {
            if !s.hasLifts {
                emptyState(
                    icon: SessionType.lift.symbol,
                    text: "Log a lift session to see progression here."
                )
            } else if s.trends.isEmpty {
                emptyState(
                    icon: SessionType.lift.symbol,
                    text: "Track exercises on your lift sessions to see weight trends here."
                )
            } else {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    ForEach(s.trends.prefix(5)) { trend in
                        ExerciseTrendCard(trend: trend)
                    }

                    if s.trends.count > 5 {
                        Text("\(s.trends.count - 5) more tracked \(s.trends.count - 5 == 1 ? "exercise" : "exercises")")
                            .font(.synText(13))
                            .foregroundStyle(SYN.textFaint)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: - Overall

    private func overallSection(_ s: ProgressSummary) -> some View {
        section("Overall") {
            HStack(spacing: 0) {
                stat(s.sessionsThisMonth, "Sessions\nthis month")
                divider
                stat(s.sessionsThisWeek, "Sessions\nthis week")
                divider
                stat(s.restDaysThisWeek, "Rest days\nthis week")
            }
            .progressCard()
        }
    }

    private var divider: some View {
        Rectangle().fill(SYN.border).frame(width: 1, height: 40)
    }

    private func stat(_ value: Int, _ label: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text("\(value)")
                .font(.synMono(22, weight: .semibold))
                .foregroundStyle(SYN.text)
                .contentTransition(.numericText())
            Text(label)
                .font(.synText(11))
                .foregroundStyle(SYN.textFaint)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Building blocks

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            EyebrowText(text: title)
                .foregroundStyle(SYN.textFaint)
            content()
        }
    }

    private func emptyState(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(SYN.textFaint)
                .frame(width: 32)
            Text(text)
                .font(.synText(14))
                .foregroundStyle(SYN.textDim)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .progressCard()
    }
}

// MARK: - Exercise trend card

private struct ExerciseTrendCard: View {
    let trend: ExerciseTrend

    private var showsSparkline: Bool { trend.points.count >= ProgressSummary.minChartPoints }

    /// Up is green, down is amber, a trade-off (one up, one down) is neutral.
    private func color(for delta: SessionDelta) -> Color {
        switch delta.tone {
        case .up:    return SYN.green
        case .down:  return SYN.amber
        case .mixed: return SYN.textDim
        case .same:  return SYN.textFaint
        }
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(trend.name)
                    .font(.synText(15, weight: .semibold))
                    .foregroundStyle(SYN.text)
                    .lineLimit(1)

                if showsSparkline {
                    Text(trend.latest.set.formatted)
                        .font(.synMono(17, weight: .semibold))
                        .foregroundStyle(SYN.cyan)
                } else {
                    // Two sessions: show the last set of each instead of a line.
                    HStack(spacing: Spacing.xs) {
                        Text(trend.first.lastSet.formatted)
                            .foregroundStyle(SYN.textDim)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SYN.textFaint)
                        Text(trend.latest.lastSet.formatted)
                            .foregroundStyle(trend.isDowntrend ? SYN.amber : SYN.cyan)
                    }
                    .font(.synMono(15, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }

                if let delta = trend.sessionDelta {
                    Text(delta.text)
                        .font(.synText(12, weight: .medium))
                        .foregroundStyle(color(for: delta))
                }
            }

            if showsSparkline {
                Spacer(minLength: Spacing.s)
                sparkline
            }
        }
        .progressCard()
        .accessibilityElement(children: .combine)
    }

    private var sparkline: some View {
        let lineColor = trend.isDowntrend ? SYN.amber : SYN.cyan
        return Chart(trend.points) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.set.weightLbs)
            )
            .foregroundStyle(lineColor)
            .interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: 2))

            if point.id == trend.latest.id {
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.set.weightLbs)
                )
                .foregroundStyle(lineColor)
                .symbolSize(30)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: trend.weightDomain)
        .frame(width: 110, height: 44)
        .accessibilityHidden(true)
    }
}

// MARK: - Grade pyramid

/// Sends per grade, highest grade on top, one row per grade with at least
/// one send. The widest bar is the grade with the most sends; the rest
/// scale against it. Grade labels are the axis, the count is the number.
private struct GradePyramid: View {
    let sendCounts: [(grade: Int, count: Int)]

    private let rowHeight: CGFloat = 24
    private let labelWidth: CGFloat = 36
    private let countWidth: CGFloat = 36

    private var maxCount: Int { sendCounts.map(\.count).max() ?? 1 }

    var body: some View {
        VStack(spacing: 5) {
            ForEach(sendCounts, id: \.grade) { item in
                HStack(spacing: Spacing.s) {
                    Text("V\(item.grade)")
                        .font(.synMono(13, weight: .semibold))
                        .foregroundStyle(SYN.text)
                        .frame(width: labelWidth, alignment: .leading)

                    GeometryReader { proxy in
                        let fraction = CGFloat(item.count) / CGFloat(max(maxCount, 1))
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(SYN.cyan)
                            .frame(width: max(proxy.size.width * fraction, rowHeight / 2))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: rowHeight)

                    Text("×\(item.count)")
                        .font(.synMono(13, weight: .medium))
                        .foregroundStyle(SYN.textDim)
                        .frame(width: countWidth, alignment: .trailing)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("V\(item.grade), \(item.count) \(item.count == 1 ? "send" : "sends")")
            }
        }
        .animation(.easeOut(duration: 0.25), value: sendCounts.map(\.count))
        .animation(.easeOut(duration: 0.25), value: sendCounts.map(\.grade))
    }
}

// MARK: - Card style

private extension View {
    func progressCard() -> some View {
        self
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(SYN.surface.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(SYN.border, lineWidth: 1)
            )
    }
}
