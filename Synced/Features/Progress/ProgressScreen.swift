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
                                .foregroundStyle(comparisonColor(comparison))
                        }
                    }

                    gradeChart(s)

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text(s.window == .last30 ? "Sends this month" : "Sends all time")
                            .font(.synText(13))
                            .foregroundStyle(SYN.textDim)
                        FlowLayout(spacing: Spacing.s) {
                            ForEach(s.sendCounts, id: \.grade) { item in
                                HStack(spacing: 4) {
                                    Text("V\(item.grade)")
                                        .font(.synMono(13, weight: .semibold))
                                    Text("×\(item.count)")
                                        .font(.synMono(11, weight: .medium))
                                        .opacity(0.7)
                                }
                                .foregroundStyle(SYN.cyan)
                                .padding(.horizontal, Spacing.m)
                                .frame(height: 30)
                                .background(Capsule().fill(SYN.cyan.opacity(0.08)))
                                .overlay(Capsule().stroke(SYN.cyan.opacity(0.5), lineWidth: 1))
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("V\(item.grade), \(item.count) \(item.count == 1 ? "send" : "sends")")
                            }
                        }
                    }
                }
                .progressCard()
            } else {
                emptyState(
                    icon: SessionType.climb.symbol,
                    text: "Log a climb session to see your grade trend."
                )
            }
        }
    }

    private func comparisonColor(_ text: String) -> Color {
        if text.hasPrefix("+") { return SYN.green }
        if text.hasPrefix("-") { return SYN.amber }
        return SYN.textFaint
    }

    private func gradeChart(_ s: ProgressSummary) -> some View {
        Chart(s.weeklyTop) { point in
            LineMark(
                x: .value("Week", point.weekStart, unit: .weekOfYear),
                y: .value("Grade", point.grade)
            )
            .foregroundStyle(SYN.cyan)
            .interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: 2))

            PointMark(
                x: .value("Week", point.weekStart, unit: .weekOfYear),
                y: .value("Grade", point.grade)
            )
            .foregroundStyle(SYN.cyan)
            .symbolSize(28)
        }
        .chartXScale(domain: s.chartDomain)
        .chartYScale(domain: 0...17)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 4, 8, 12, 17]) { value in
                AxisGridLine().foregroundStyle(SYN.border)
                AxisValueLabel {
                    if let grade = value.as(Int.self) {
                        Text("V\(grade)")
                            .font(.synMono(11))
                            .foregroundStyle(SYN.textFaint)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine().foregroundStyle(SYN.border.opacity(0.5))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.synText(11))
                            .foregroundStyle(SYN.textFaint)
                    }
                }
            }
        }
        .frame(height: 160)
        .accessibilityLabel("Highest grade sent per week")
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
            } else if s.trends.isEmpty && s.firstLogs.isEmpty {
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

                    if !s.firstLogs.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            Text("First logs")
                                .font(.synText(13))
                                .foregroundStyle(SYN.textDim)
                            ForEach(s.firstLogs) { trend in
                                HStack {
                                    Text(trend.name)
                                        .font(.synText(15, weight: .medium))
                                        .foregroundStyle(SYN.text)
                                    Spacer()
                                    Text(trend.latest.set.formatted)
                                        .font(.synMono(13))
                                        .foregroundStyle(SYN.textDim)
                                }
                            }
                        }
                        .padding(.top, s.trends.isEmpty ? 0 : Spacing.s)
                        .progressCard()
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

    private var change: Double { trend.latest.set.weightLbs - trend.first.set.weightLbs }

    private var changeText: String {
        let amount = abs(change).rounded() == abs(change)
            ? String(Int(abs(change)))
            : abs(change).formatted(.number.precision(.fractionLength(1)))
        let since = trend.first.date.formatted(.dateTime.month(.abbreviated).day())
        if change > 0 { return "+\(amount) lbs since \(since)" }
        if change < 0 { return "-\(amount) lbs since \(since)" }
        return "Holding since \(since)"
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(trend.name)
                    .font(.synText(15, weight: .semibold))
                    .foregroundStyle(SYN.text)
                    .lineLimit(1)
                Text(trend.latest.set.formatted)
                    .font(.synMono(17, weight: .semibold))
                    .foregroundStyle(SYN.cyan)
                Text(changeText)
                    .font(.synText(12, weight: .medium))
                    .foregroundStyle(change > 0 ? SYN.green : change < 0 ? SYN.amber : SYN.textFaint)
            }

            Spacer(minLength: Spacing.s)

            Chart(trend.points) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.set.weightLbs)
                )
                .foregroundStyle(SYN.cyan)
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 2))

                if point.id == trend.latest.id {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.set.weightLbs)
                    )
                    .foregroundStyle(SYN.cyan)
                    .symbolSize(30)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(width: 110, height: 44)
            .accessibilityHidden(true)
        }
        .progressCard()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Card style and flow layout

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

/// Wraps chips onto new lines when a row runs out of width.
private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: .unspecified)
                x += size.width + spacing
            }
        }
    }

    private struct Row {
        var indices: [Int] = []
        var y: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            var row = rows[rows.count - 1]
            let needed = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            if needed > maxWidth, !row.indices.isEmpty {
                let y = row.y + row.height + spacing
                rows.append(Row(indices: [index], y: y, width: size.width, height: size.height))
                continue
            }
            row.indices.append(index)
            row.width = needed
            row.height = max(row.height, size.height)
            rows[rows.count - 1] = row
        }
        return rows.filter { !$0.indices.isEmpty }
    }
}
