import SwiftUI

/// Progress tab, three sections from one fetch: Climbing (top grade this
/// month, pyramid, first-at-grade milestones), Improving (lifts whose
/// latest top set beat the previous one), and Recent Lifts (every exercise
/// ever logged, each opening its history).
struct ProgressScreen: View {
    @State private var store = ProgressStore()
    @State private var showingProfile = false
    @State private var historyTarget: ExerciseHistory?
    @Environment(\.scenePhase) private var scenePhase

    private var report: ProgressReport {
        ProgressReport(sessions: store.sessions)
    }

    var body: some View {
        ZStack {
            // Hero glow behind the header only; it fades out before the
            // sections below. An overlay, so its oversized frame never
            // affects the screen's layout.
            ScreenBackground()
                .overlay(alignment: .top) {
                    HeroGlow(height: 620)
                        .offset(y: -40)
                }

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
                        let report = report
                        climbingSection(report)
                        improvingSection(report)
                        recentLiftsSection(report)
                    }
                }
                .padding(.horizontal, Spacing.pageH)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.tabBarClearance)
            }
            .scrollIndicators(.hidden)
            .refreshable { await store.load() }
        }
        // Refetch every time the tab appears so new logs show up.
        .onAppear { Task { await store.load() } }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await store.load() } }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileSheet()
        }
        .sheet(item: $historyTarget) { history in
            ExerciseHistorySheet(history: history)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                EyebrowText(text: "Your trends")
                    .foregroundStyle(SYN.textFaint)

                Spacer()

                // Same placement and hit target as Today's icon.
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
        }
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

    // MARK: - Climbing

    @ViewBuilder
    private func climbingSection(_ r: ProgressReport) -> some View {
        section("Climbing") {
            if !r.hasClimbedEver {
                emptyState(
                    icon: SessionType.climb.symbol,
                    text: "Log a climb session to see your grades here."
                )
            } else {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if let top = r.topGradeThisMonth {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Highest grade this month")
                                .font(.synText(13))
                                .foregroundStyle(SYN.textDim)
                            Text("V\(top)")
                                .font(.synMono(44, weight: .semibold))
                                .foregroundStyle(SYN.cyan)
                                .shadow(color: SYN.cyan.opacity(0.35), radius: 14)
                                .contentTransition(.numericText())
                            let comparison = monthComparison(top: top, lastMonth: r.topGradeLastMonth)
                            Text(comparison.text)
                                .font(.synText(13, weight: .medium))
                                .foregroundStyle(comparison.color)
                        }
                    } else {
                        Text("No sends this month yet.")
                            .font(.synText(14))
                            .foregroundStyle(SYN.textDim)
                    }

                    if !r.sendCounts.isEmpty {
                        GradePyramid(sendCounts: r.sendCounts)
                    }

                    if !r.milestones.isEmpty {
                        milestoneList(r.milestones)
                    }
                }
                .progressCard()
            }
        }
    }

    /// Up is green (the sanctioned Progress delta), down is amber, flat or
    /// unknown is dim.
    private func monthComparison(top: Int, lastMonth: Int?) -> (text: String, color: Color) {
        guard let lastMonth else { return ("No climbs last month", SYN.textDim) }
        let delta = top - lastMonth
        if delta > 0 { return ("+\(delta) from last month", SYN.green) }
        if delta < 0 { return ("\(delta) from last month", SYN.amber) }
        return ("Same as last month", SYN.textDim)
    }

    private func milestoneList(_ milestones: [GradeMilestone]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Rectangle().fill(SYN.border).frame(height: 0.5)
            ForEach(milestones) { milestone in
                HStack {
                    Text("First V\(milestone.grade)")
                        .font(.synText(14, weight: .medium))
                        .foregroundStyle(SYN.text)
                    Spacer()
                    Text(milestone.date.shortDayLabel)
                        .font(.synMono(13))
                        .foregroundStyle(SYN.textDim)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: - Improving

    @ViewBuilder
    private func improvingSection(_ r: ProgressReport) -> some View {
        section("Improving") {
            if r.improving.isEmpty {
                Text("Keep training. Improvements show up here when they do.")
                    .font(.synText(14))
                    .foregroundStyle(SYN.textDim)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .progressCard()
            } else {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    ForEach(r.improving) { improvement in
                        ImprovementCard(
                            improvement: improvement,
                            recentTops: store.recentTopSets(for: improvement.history.name).chartValues
                        )
                    }
                }
            }
        }
    }

    // MARK: - Recent lifts

    @ViewBuilder
    private func recentLiftsSection(_ r: ProgressReport) -> some View {
        section("Recent lifts") {
            if r.recentLifts.isEmpty {
                Text("No lifts logged yet.")
                    .font(.synText(14))
                    .foregroundStyle(SYN.textDim)
                    .frame(maxWidth: .infinity)
                    .progressCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(r.recentLifts.enumerated()), id: \.element.id) { index, history in
                        if index > 0 {
                            Rectangle().fill(SYN.border).frame(height: 0.5)
                        }
                        Button { historyTarget = history } label: {
                            RecentLiftRow(history: history)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .frame(maxWidth: .infinity)
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

// MARK: - Improvement card

private struct ImprovementCard: View {
    let improvement: ExerciseImprovement
    /// Top-set weights (reps for bodyweight) from recent sessions, oldest first.
    let recentTops: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(improvement.history.name)
                .font(.synText(15, weight: .semibold))
                .foregroundStyle(SYN.text)
                .lineLimit(1)

            HStack(spacing: Spacing.xs) {
                Text(improvement.previous.formatted)
                    .foregroundStyle(SYN.textDim)
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SYN.textFaint)
                Text(improvement.current.formatted)
                    .foregroundStyle(SYN.cyan)
            }
            .font(.synMono(15, weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            Text(improvement.delta.text)
                .font(.synText(12, weight: .medium))
                .foregroundStyle(SYN.green)

            if recentTops.count >= 2 {
                GeometryReader { proxy in
                    MiniBarChart(values: recentTops, width: proxy.size.width)
                }
                .frame(height: 24)
                .padding(.vertical, Spacing.s)
            }
        }
        .progressCard()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Recent lift row

private struct RecentLiftRow: View {
    let history: ExerciseHistory

    var body: some View {
        HStack(spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(history.name)
                    .font(.synText(15, weight: .semibold))
                    .foregroundStyle(SYN.text)
                    .lineLimit(1)
                if let top = history.latest?.top {
                    Text(top.formatted)
                        .font(.synMono(13))
                        .foregroundStyle(SYN.textDim)
                }
            }
            Spacer(minLength: Spacing.s)
            if let latest = history.latest {
                Text(latest.date.relativeDayLabel())
                    .font(.synText(13))
                    .foregroundStyle(SYN.textDim)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(SYN.textFaint)
        }
        .padding(.vertical, Spacing.m)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows every session of this exercise")
    }
}

// MARK: - Exercise history

/// Every session of one exercise, newest first, with all its sets.
private struct ExerciseHistorySheet: View {
    let history: ExerciseHistory
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    EyebrowText(text: "History")
                        .foregroundStyle(SYN.textFaint)
                    Text(history.name)
                        .font(.synDisplay(24, weight: .bold))
                        .foregroundStyle(SYN.text)
                        .kerning(-0.5)
                        .lineLimit(2)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SYN.textDim)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(SYN.surfaceHi))
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, Spacing.pageH)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.md)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(history.sessions.enumerated()), id: \.element.id) { index, session in
                        if index > 0 {
                            Rectangle().fill(SYN.border).frame(height: 0.5)
                        }
                        // "Oct 8: 185 × 5, 185 × 4, 180 × 5"
                        (Text("\(session.date.shortDayLabel): ").foregroundColor(SYN.textDim)
                         + Text(session.sets.map(\.compact).joined(separator: ", ")).foregroundColor(SYN.text))
                            .font(.synMono(14))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, Spacing.m)
                    }
                }
                .padding(.horizontal, Spacing.pageH)
                .padding(.bottom, Spacing.lg)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(SYN.bg)
        .presentationCornerRadius(Radius.card * 2)
    }
}

extension Date {
    /// "Oct 3", with the year added when it is not this year.
    var shortDayLabel: String {
        let cal = WeekStore.calendar
        return cal.isDate(self, equalTo: Date(), toGranularity: .year)
            ? formatted(.dateTime.month(.abbreviated).day())
            : formatted(.dateTime.month(.abbreviated).day().year())
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
