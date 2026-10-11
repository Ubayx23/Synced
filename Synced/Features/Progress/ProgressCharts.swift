import SwiftUI

// MARK: - Grade line

/// Max grade sent per week across the scope. Weeks without a send break
/// the line. A dashed line marks the all-time best, labeled in a right
/// gutter so it never sits on a dot. Dots mark new bests; tapping one shows
/// "First V5 · Oct 3".
struct GradeLineChart: View {
    let report: ProgressReport
    let width: CGFloat
    /// Grade of the dot whose tooltip is showing.
    @Binding var selected: Int?

    static let height: CGFloat = 146
    private let plotHeight: CGFloat = 128
    private let top: CGFloat = 24
    private let bottom: CGFloat = 112
    private let axisWidth: CGFloat = 24
    private let bestWidth: CGFloat = 46

    private var count: Int { report.weeks.count }
    private var plotMinX: CGFloat { axisWidth + 6 }
    private var plotMaxX: CGFloat { width - bestWidth - 6 }

    private var values: [Int] { report.weeklyMax.compactMap { $0 } }
    private var lo: Int { max(0, (values.min() ?? 0) - 1) }
    private var hi: Int { max(report.allTimeBest ?? 0, values.max() ?? 0, lo + 1) }

    private func x(_ week: Int) -> CGFloat {
        count <= 1 ? (plotMinX + plotMaxX) / 2 : plotMinX + CGFloat(week) * (plotMaxX - plotMinX) / CGFloat(count - 1)
    }

    private func y(_ grade: Int) -> CGFloat {
        bottom - CGFloat(grade - lo) / CGFloat(hi - lo) * (bottom - top)
    }

    /// Runs of consecutive weeks with a send.
    private var segments: [[CGPoint]] {
        var runs: [[CGPoint]] = []
        var run: [CGPoint] = []
        for (week, value) in report.weeklyMax.enumerated() {
            if let value {
                run.append(CGPoint(x: x(week), y: y(value)))
            } else if !run.isEmpty {
                runs.append(run)
                run = []
            }
        }
        if !run.isEmpty { runs.append(run) }
        return runs
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                if let best = report.allTimeBest {
                    var dash = Path()
                    dash.move(to: CGPoint(x: plotMinX, y: y(best)))
                    dash.addLine(to: CGPoint(x: width - bestWidth, y: y(best)))
                    context.stroke(dash, with: .color(SYN.textFaint), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
                for run in segments {
                    guard run.count > 1, let first = run.first, let last = run.last else {
                        // A lone climbing week still shows as a point.
                        if let point = run.first {
                            context.fill(Path(ellipseIn: CGRect(x: point.x - 2.5, y: point.y - 2.5, width: 5, height: 5)), with: .color(SYN.cyan))
                        }
                        continue
                    }
                    var line = Path()
                    line.addLines(run)
                    var area = line
                    area.addLine(to: CGPoint(x: last.x, y: plotHeight))
                    area.addLine(to: CGPoint(x: first.x, y: plotHeight))
                    area.closeSubpath()
                    context.fill(
                        area,
                        with: .linearGradient(
                            Gradient(colors: [SYN.cyan.opacity(0.26), SYN.cyan.opacity(0)]),
                            startPoint: CGPoint(x: 0, y: top),
                            endPoint: CGPoint(x: 0, y: plotHeight)
                        )
                    )
                    context.stroke(line, with: .color(SYN.cyan), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }
            .frame(width: width, height: plotHeight)

            ForEach(axisGrades, id: \.self) { grade in
                Text("V\(grade)")
                    .font(.synMono(10))
                    .foregroundStyle(SYN.textFaint)
                    .frame(width: axisWidth, alignment: .leading)
                    .position(x: axisWidth / 2, y: y(grade))
            }

            if let best = report.allTimeBest {
                HStack(spacing: 4) {
                    Text("Best").font(.synText(10, weight: .medium))
                    Text("V\(best)").font(.synMono(10))
                }
                .foregroundStyle(SYN.textFaint)
                .fixedSize()
                .position(x: width - bestWidth / 2 + 3, y: y(best))
            }

            ForEach(monthLabels, id: \.week) { label in
                Text(label.text)
                    .font(.synText(10, weight: .medium))
                    .foregroundStyle(SYN.textFaint)
                    .fixedSize()
                    .offset(x: label.x, y: 134)
            }

            ForEach(report.bests) { best in
                let isSelected = selected == best.grade
                Button {
                    selected = isSelected ? nil : best.grade
                } label: {
                    ZStack {
                        if isSelected {
                            Circle().fill(SYN.cyan.opacity(0.22)).frame(width: 21, height: 21)
                        }
                        Circle()
                            .fill(SYN.cyan)
                            .frame(width: 9, height: 9)
                            .background(Circle().fill(SYN.card).frame(width: 13, height: 13))
                    }
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(x: x(best.week), y: y(best.grade))
                .accessibilityLabel("First V\(best.grade), \(best.date.shortDayLabel)")
            }

            if let grade = selected, let best = report.bests.first(where: { $0.grade == grade }) {
                tooltip(best)
            }
        }
        .frame(width: width, height: Self.height, alignment: .topLeading)
    }

    /// Every grade between lo and hi, or every other one when the span is
    /// wide, always including the top.
    private var axisGrades: [Int] {
        let step = hi - lo <= 4 ? 1 : 2
        return stride(from: hi, through: lo, by: -step).map { $0 }
    }

    private struct MonthLabel { let week: Int; let text: String; let x: CGFloat }

    /// A label where the month changes (by each week's Thursday). A cramped
    /// first label is dropped, then labels closer than 30pt are skipped.
    private var monthLabels: [MonthLabel] {
        let cal = WeekStore.calendar
        var labels: [MonthLabel] = []
        var lastMonth = -1
        for (week, start) in report.weeks.enumerated() {
            let thursday = cal.date(byAdding: .day, value: 3, to: start) ?? start
            let month = cal.component(.month, from: thursday)
            if month != lastMonth {
                labels.append(MonthLabel(week: week, text: thursday.formatted(.dateTime.month(.abbreviated)), x: max(axisWidth, x(week) - 4)))
                lastMonth = month
            }
        }
        if labels.count > 1, labels[1].x - labels[0].x < 30 { labels.removeFirst() }
        var kept: [MonthLabel] = []
        for label in labels where kept.last.map({ label.x - $0.x >= 30 }) ?? true {
            kept.append(label)
        }
        return kept
    }

    private func tooltip(_ best: GradeBest) -> some View {
        let dotY = y(best.grade)
        let centerY = dotY < 56 ? dotY + 28 : dotY - 28
        return HStack(spacing: 5) {
            Text("First").foregroundStyle(SYN.text)
            Text("V\(best.grade)").font(.synMono(12, weight: .medium)).foregroundStyle(SYN.cyan)
            Text("·").foregroundStyle(SYN.textFaint)
            Text(best.date.shortDayLabel).font(.synMono(12, weight: .medium)).foregroundStyle(SYN.textDim)
        }
        .font(.synText(12, weight: .medium))
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(SYN.tooltip))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(SYN.text.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 10, y: 8)
        .fixedSize()
        .position(x: min(max(x(best.week), 66), width - 66), y: centerY)
        .allowsHitTesting(false)
        .transition(.opacity)
    }
}

/// B state: under three climbing weeks. A faint baseline, no data drawn.
struct GradeLineEmpty: View {
    let needed: Int

    var body: some View {
        ZStack(alignment: .topLeading) {
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: 1000, y: 0))
            }
            .stroke(SYN.border, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            .frame(height: 1)
            .clipped()
            .offset(y: 110)
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Log a few climbs and your grade line shows up here.")
                    .font(.synText(15, weight: .medium))
                    .foregroundStyle(SYN.text)
                    .lineSpacing(3)
                    .frame(maxWidth: 230, alignment: .leading)
                HStack(spacing: 4) {
                    Text("\(needed)").font(.synMono(13)).foregroundStyle(SYN.text)
                    Text(needed == 1 ? "more climb to start the line" : "more climbs to start the line")
                        .font(.synText(13))
                        .foregroundStyle(SYN.textDim)
                }
            }
            .offset(y: 28)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: GradeLineChart.height, alignment: .topLeading)
    }
}

// MARK: - Consistency

/// One cell per day from the user's start (or the range start) through
/// today, a column per Monday-start week, growing left to right. Climb
/// filled cyan, lift a cyan outline, rest gray, an empty day a faint
/// square. Days before the start and after today are not drawn. Under four
/// weeks the cells are large; they shrink toward the fitted size until the
/// grid is twelve weeks wide.
struct ConsistencyGrid: View {
    let report: ProgressReport
    let width: CGFloat

    private let labelWidth: CGFloat = 14
    private let labelGap: CGFloat = 8
    private var count: Int { report.gridWeeks.count }
    private var available: CGFloat { width - labelWidth - labelGap }

    private static func gap(columns: Int) -> CGFloat { columns > 16 ? 3 : columns > 8 ? 5 : 6 }

    /// The cell that fits `columns` across, capped at 30.
    private func fitted(columns: Int) -> CGFloat {
        let gap = Self.gap(columns: columns)
        let fit = (available - gap * CGFloat(columns - 1)) / CGFloat(columns)
        return min(30, (fit * 10).rounded(.down) / 10)
    }

    private var gap: CGFloat { Self.gap(columns: count) }

    /// 28 under four weeks, easing to the twelve-week fit by week twelve,
    /// then fitted to the width.
    private var cell: CGFloat {
        let large: CGFloat = 28
        if count < 4 { return large }
        if count < 12 {
            let t = CGFloat(count - 4) / 8
            return (large + (fitted(columns: 12) - large) * t).rounded()
        }
        return fitted(columns: count)
    }

    private var radius: CGFloat { cell >= 18 ? 5 : cell > 12 ? 4 : 2.5 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !monthLabels.isEmpty {
                ZStack(alignment: .topLeading) {
                    ForEach(monthLabels, id: \.column) { label in
                        Text(label.text)
                            .font(.synText(10, weight: .medium))
                            .foregroundStyle(SYN.textFaint)
                            .fixedSize()
                            .offset(x: labelWidth + labelGap + CGFloat(label.column) * (cell + gap))
                    }
                }
                .frame(height: 10, alignment: .topLeading)
            }

            VStack(alignment: .leading, spacing: gap) {
                ForEach(0..<7, id: \.self) { row in
                    HStack(spacing: labelGap) {
                        Text(["M", "T", "W", "T", "F", "S", "S"][row])
                            .font(.synText(10, weight: .medium))
                            .foregroundStyle(SYN.textFaint)
                            .frame(width: labelWidth, alignment: .leading)
                        HStack(spacing: gap) {
                            ForEach(0..<count, id: \.self) { column in
                                dayCell(row: row, column: column)
                            }
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(report.sessionCount) sessions since \(report.gridStart.shortDayLabel)")
    }

    private func day(row: Int, column: Int) -> Date? {
        let cal = WeekStore.calendar
        return cal.date(byAdding: .day, value: row, to: report.gridWeeks[column]).map { cal.startOfDay(for: $0) }
    }

    @ViewBuilder
    private func dayCell(row: Int, column: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if let day = day(row: row, column: column), report.isInGrid(day) {
            switch report.dayMarks[day] {
            case .climb: shape.fill(SYN.cyan).frame(width: cell, height: cell)
            case .lift:  shape.strokeBorder(SYN.cyan, lineWidth: 1.5).frame(width: cell, height: cell)
            case .rest:  shape.fill(SYN.restDot).frame(width: cell, height: cell)
            case nil:    shape.fill(SYN.surfaceHi).frame(width: cell, height: cell)
            }
        } else {
            Color.clear.frame(width: cell, height: cell)
        }
    }

    private struct MonthLabel { let column: Int; let text: String }

    /// Only when the grid spans two or more months: the month at each
    /// column where it changes, by the week's Thursday (or the first drawn
    /// day, when that is later). Past twelve weeks the last two columns
    /// stay unlabeled.
    private var monthLabels: [MonthLabel] {
        let cal = WeekStore.calendar
        guard cal.component(.month, from: report.gridStart) != cal.component(.month, from: report.today)
                || cal.component(.year, from: report.gridStart) != cal.component(.year, from: report.today)
        else { return [] }
        var labels: [MonthLabel] = []
        var lastMonth = -1
        for (column, start) in report.gridWeeks.enumerated() {
            let thursday = cal.date(byAdding: .day, value: 3, to: start) ?? start
            let anchor = max(thursday, report.gridStart)
            let month = cal.component(.month, from: anchor)
            if month != lastMonth {
                if !(count > 12 && column > count - 3) {
                    labels.append(MonthLabel(column: column, text: anchor.formatted(.dateTime.month(.abbreviated))))
                }
                lastMonth = month
            }
        }
        return labels
    }
}

/// Zero sessions: one cell for today, outlined in cyan.
struct ConsistencyFirstCell: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .strokeBorder(SYN.cyan, lineWidth: 1.5)
            .frame(width: 28, height: 28)
            .accessibilityLabel("Today")
    }
}

// MARK: - Sparkline

/// Top-set effort over recent sessions, ending in a dot.
struct Sparkline: View {
    let values: [Double]
    let width: CGFloat
    let height: CGFloat
    var lineWidth: CGFloat = 1.5
    var dotRadius: CGFloat = 2.5

    var body: some View {
        Canvas { context, _ in
            guard let low = values.min(), let high = values.max() else { return }
            let points = values.enumerated().map { index, value in
                CGPoint(
                    x: values.count == 1 ? width / 2 : 2 + CGFloat(index) * (width - 4) / CGFloat(values.count - 1),
                    y: high == low ? height / 2 : height - 3 - CGFloat((value - low) / (high - low)) * (height - 6)
                )
            }
            var line = Path()
            line.addLines(points)
            context.stroke(line, with: .color(SYN.cyan.opacity(0.85)), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            if let last = points.last {
                context.fill(
                    Path(ellipseIn: CGRect(x: last.x - dotRadius, y: last.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)),
                    with: .color(SYN.cyan)
                )
            }
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}
