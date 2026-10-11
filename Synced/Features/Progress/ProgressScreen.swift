import SwiftUI

/// Progress tab, from one fetch. A 4W / 12W / ALL toggle scopes the grade
/// line, Improving, Consistency, Lifts, and both sheets. The hero number
/// always compares this calendar month with last month.
struct ProgressScreen: View {
    @State private var store = ProgressStore()
    @State private var scope: ProgressScope = .twelveWeeks
    @State private var selectedBest: Int?
    @State private var showAllLifts = false
    @State private var sheet: ProgressSheet?
    @State private var showingProfile = false
    @Environment(\.scenePhase) private var scenePhase

    private enum ProgressSheet: Identifiable {
        case grades
        /// Keyed by exerciseMatchKey.
        case lift(String)

        var id: String {
            switch self {
            case .grades:        return "grades"
            case .lift(let key): return "lift-\(key)"
            }
        }
    }

    private var report: ProgressReport {
        ProgressReport(sessions: store.sessions, scope: scope)
    }

    var body: some View {
        GeometryReader { geo in
            let contentWidth = geo.size.width - Spacing.l * 2
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    scopeToggle
                        .padding(.top, Spacing.m)

                    switch store.loadState {
                    case .loading where store.sessions.isEmpty:
                        SwiftUI.ProgressView()
                            .tint(SYN.textDim)
                            .frame(maxWidth: .infinity)
                            .padding(.top, Spacing.xxl)
                    case .failed(let message) where store.sessions.isEmpty:
                        failure(message)
                            .padding(.top, Spacing.l)
                    default:
                        let report = report
                        hero(report, width: contentWidth - Spacing.l * 2)
                            .padding(.top, Spacing.l)
                        improvingSection(report)
                            .padding(.top, 28)
                        consistencySection(report, width: contentWidth)
                            .padding(.top, 28)
                        liftsSection(report)
                            .padding(.top, 28)
                    }
                }
                .padding(.horizontal, Spacing.l)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .refreshable { await store.load() }
        }
        .background(SYN.bg.ignoresSafeArea())
        // Content fades out under the status bar instead of colliding with it.
        .overlay(alignment: .top) {
            GeometryReader { geo in
                LinearGradient(
                    stops: [.init(color: SYN.bg, location: 0.72), .init(color: SYN.bg.opacity(0), location: 1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: geo.safeAreaInsets.top)
                .offset(y: -geo.safeAreaInsets.top)
            }
            .allowsHitTesting(false)
        }
        // Refetch every time the tab appears so new logs show up.
        .onAppear { Task { await store.load() } }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await store.load() } }
        }
        .onChange(of: scope) { _, _ in
            selectedBest = nil
            showAllLifts = false
        }
        .sheet(isPresented: $showingProfile) {
            ProfileSheet()
        }
        .sheet(item: $sheet) { sheet in
            sheetContent(sheet)
                .presentationBackground(SYN.card)
                .presentationCornerRadius(24)
                .presentationDragIndicator(.hidden)
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: ProgressSheet) -> some View {
        let report = report
        switch sheet {
        case .grades:
            GradeBreakdownSheet(report: report)
                .presentationDetents([.height(638)])
        case .lift(let key):
            if let history = report.histories.first(where: { $0.id == key }) {
                LiftHistorySheet(report: report, history: history)
                    .presentationDetents([.height(756)])
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            eyebrow("Progress")
            Spacer()
            Button { showingProfile = true } label: {
                Text(initials)
                    .font(.synText(13, weight: .medium))
                    .foregroundStyle(SYN.textDim)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(SYN.surfaceHi))
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, -Spacing.xs)
            .accessibilityLabel("Profile")
        }
        .frame(height: 44)
    }

    /// Same as Today's avatar: the first two letters of the email's local
    /// part, since no names are stored.
    private var initials: String {
        let local = supabase.auth.currentUser?.email?.split(separator: "@").first.map(String.init) ?? ""
        let letters = local.filter(\.isLetter)
        return String((letters.isEmpty ? local : letters).prefix(2)).uppercased()
    }

    // MARK: - Scope toggle

    private var scopeToggle: some View {
        HStack(spacing: 4) {
            ForEach(ProgressScope.allCases) { option in
                let isSelected = option == scope
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { scope = option }
                } label: {
                    Text(option.rawValue)
                        .font(.synMono(13, weight: .semibold))
                        .tracking(0.26)
                        .foregroundStyle(isSelected ? SYN.cyan : SYN.textDim)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(isSelected ? SYN.surfaceHi : .clear)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(3)
        .frame(height: 36)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(SYN.card))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(SYN.border, lineWidth: 0.5))
    }

    // MARK: - Hero

    private func hero(_ r: ProgressReport, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            eyebrow("Top grade · \(r.monthName)")

            HStack(spacing: 14) {
                Text(r.topGradeThisMonth.map { "V\($0)" } ?? "V·")
                    .font(.synMono(56, weight: .semibold))
                    .kerning(-1.68)
                    .foregroundStyle(SYN.cyan)
                    .shadow(color: SYN.cyan.opacity(0.35), radius: 14)
                    .frame(height: 56)
                monthPill(r)
            }
            .padding(.top, 10)

            Group {
                if r.climbingWeeks >= ProgressReport.minimumClimbingWeeks {
                    GradeLineChart(report: r, width: width, selected: $selectedBest)
                        .animation(.easeOut(duration: 0.15), value: selectedBest)
                } else {
                    GradeLineEmpty(needed: ProgressReport.minimumClimbingWeeks - r.climbingWeeks)
                }
            }
            .padding(.top, 18)

            HStack {
                Text("Max grade sent per week")
                    .font(.synText(12))
                    .foregroundStyle(SYN.textFaint)
                Spacer()
                Button { sheet = .grades } label: {
                    HStack(spacing: 6) {
                        Text("Grade breakdown")
                            .font(.synText(13, weight: .semibold))
                        LineGlyph(kind: .chevron, size: 12)
                    }
                    .foregroundStyle(SYN.cyan)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
            .overlay(alignment: .top) { Rectangle().fill(SYN.border).frame(height: 0.5) }
            .padding(.top, 10)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.top, Spacing.l)
        .padding(.bottom, 4)
        .background(
            RoundedRectangle(cornerRadius: Radius.hero, style: .continuous)
                .fill(SYN.card)
                .shadow(color: SYN.cyan.opacity(0.3), radius: 19)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.hero, style: .continuous)
                .stroke(SYN.cyan.opacity(0.24), lineWidth: 1)
                .allowsHitTesting(false)
        )
    }

    /// +N green, same dim, -N amber, against last calendar month.
    private func monthPill(_ r: ProgressReport) -> some View {
        let number: String
        let text: String
        let color: Color
        let fill: Color
        switch (r.topGradeThisMonth, r.topGradeLastMonth) {
        case (nil, _):
            (number, text, color, fill) = ("", "No sends yet this month", SYN.textDim, SYN.text.opacity(0.06))
        case (_, nil):
            (number, text, color, fill) = ("", "First month logged", SYN.textDim, SYN.text.opacity(0.06))
        case (let now?, let before?) where now > before:
            (number, text, color, fill) = ("+\(now - before)", "from \(r.lastMonthName)", SYN.green, SYN.green.opacity(0.14))
        case (let now?, let before?) where now < before:
            (number, text, color, fill) = ("-\(before - now)", "from \(r.lastMonthName)", SYN.amber, SYN.amber.opacity(0.14))
        default:
            (number, text, color, fill) = ("", "Same as \(r.lastMonthName)", SYN.textDim, SYN.text.opacity(0.06))
        }
        return HStack(spacing: 4) {
            if !number.isEmpty {
                Text(number).font(.synMono(12, weight: .semibold))
            }
            Text(text).font(.synText(12, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .frame(height: 26)
        .background(Capsule().fill(fill))
    }

    // MARK: - Improving

    private func improvingSection(_ r: ProgressReport) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .firstTextBaseline) {
                eyebrow("Improving")
                Spacer()
                if !r.improving.isEmpty {
                    HStack(spacing: 4) {
                        Text("\(r.improving.count)").font(.synMono(12))
                        Text(r.improving.count == 1 ? "lift" : "lifts").font(.synText(12))
                    }
                    .foregroundStyle(SYN.textFaint)
                }
            }

            switch r.improving.count {
            case 0:
                VStack(alignment: .leading, spacing: 6) {
                    Text(r.totalLiftSessions < 2
                         ? "Log a lift a second time and any gain shows up here."
                         : "No new top sets in the \(r.scope.label.lowercased()).")
                        .font(.synText(15, weight: .medium))
                        .foregroundStyle(SYN.text)
                    Text(r.totalLiftSessions < 2
                         ? "Each card compares your latest top set with your first one in this range."
                         : "Beat a top set and the lift shows up here.")
                        .font(.synText(13))
                        .foregroundStyle(SYN.textDim)
                }
                .lineSpacing(2)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .progressCard()
            case 1:
                singleImprovement(r.improving[0])
            default:
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(r.improving) { improvement in
                            improvementCard(improvement)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .contentMargins(.horizontal, Spacing.l, for: .scrollContent)
                .padding(.horizontal, -Spacing.l)
            }
        }
    }

    private func improvementCard(_ item: LiftImprovement) -> some View {
        Button { sheet = .lift(item.id) } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(item.history.name)
                    .font(.synText(13, weight: .semibold))
                    .foregroundStyle(SYN.text)
                    .lineLimit(1)
                Spacer(minLength: 0)
                setChange(item, size: 12)
                Spacer(minLength: 0)
                Sparkline(values: item.spark, width: 132, height: 24)
                Spacer(minLength: 0)
                Text(item.latestDate.shortDayLabel)
                    .font(.synMono(11))
                    .foregroundStyle(SYN.textFaint)
            }
            .padding(14)
            .frame(width: 160, height: 120, alignment: .leading)
            .progressCard()
        }
        .buttonStyle(.plain)
    }

    private func singleImprovement(_ item: LiftImprovement) -> some View {
        Button { sheet = .lift(item.id) } label: {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(item.history.name)
                        .font(.synText(15, weight: .semibold))
                        .foregroundStyle(SYN.text)
                        .lineLimit(1)
                    setChange(item, size: 15)
                    Text(item.latestDate.shortDayLabel)
                        .font(.synMono(11))
                        .foregroundStyle(SYN.textFaint)
                }
                Spacer(minLength: 0)
                Sparkline(values: item.spark, width: 110, height: 44, lineWidth: 1.75, dotRadius: 3)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .progressCard()
        }
        .buttonStyle(.plain)
    }

    /// "155 × 6 → 155 × 9".
    private func setChange(_ item: LiftImprovement, size: CGFloat) -> some View {
        HStack(spacing: size > 12 ? 6 : 5) {
            Text(item.first.compact).foregroundStyle(SYN.textDim)
            Text("→").foregroundStyle(SYN.textFaint)
            Text(item.latest.compact).foregroundStyle(SYN.cyan)
        }
        .font(.synMono(size, weight: .medium))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    // MARK: - Consistency

    private func consistencySection(_ r: ProgressReport, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            eyebrow("Consistency")
            VStack(alignment: .leading, spacing: 0) {
                consistencySummary(r)
                ConsistencyGrid(report: r, width: width - Spacing.md * 2)
                    .padding(.top, Spacing.md)
                HStack(spacing: Spacing.md) {
                    legend("Climb") { RoundedRectangle(cornerRadius: 3).fill(SYN.cyan) }
                    legend("Lift") { RoundedRectangle(cornerRadius: 3).strokeBorder(SYN.cyan, lineWidth: 1.5) }
                    legend("Rest") { RoundedRectangle(cornerRadius: 3).fill(SYN.restDot) }
                }
                .padding(.top, Spacing.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) { Rectangle().fill(SYN.border).frame(height: 0.5) }
                .padding(.top, Spacing.md)
            }
            .padding(Spacing.md)
            .progressCard()
        }
    }

    /// "18 sessions · 1.5 per week", or "2 sessions · since Oct 8" for a
    /// new user.
    private func consistencySummary(_ r: ProgressReport) -> some View {
        HStack(spacing: 5) {
            Text("\(r.sessionCount)").font(.synMono(14)).foregroundStyle(SYN.text)
            if r.isNewUser, let first = r.firstSessionDate {
                Text(r.sessionCount == 1 ? "session · since" : "sessions · since")
                Text(first.shortDayLabel).font(.synMono(14)).foregroundStyle(SYN.text)
            } else {
                Text(r.sessionCount == 1 ? "session ·" : "sessions ·")
                Text(r.perWeek.formatted(.number.precision(.fractionLength(1)))).font(.synMono(14)).foregroundStyle(SYN.text)
                Text("per week")
            }
        }
        .font(.synText(14))
        .foregroundStyle(SYN.textDim)
        .lineLimit(1)
    }

    private func legend<Swatch: View>(_ title: String, @ViewBuilder swatch: () -> Swatch) -> some View {
        HStack(spacing: 6) {
            swatch().frame(width: 10, height: 10)
            Text(title)
                .font(.synText(11))
                .foregroundStyle(SYN.textDim)
        }
    }

    // MARK: - Lifts

    private func liftsSection(_ r: ProgressReport) -> some View {
        let rows = showAllLifts ? r.lifts : Array(r.lifts.prefix(5))
        return VStack(alignment: .leading, spacing: Spacing.m) {
            eyebrow("Lifts")
            VStack(spacing: 0) {
                if rows.isEmpty {
                    Text("No lifts logged in the \(r.scope.label.lowercased()).")
                        .font(.synText(15, weight: .medium))
                        .foregroundStyle(SYN.textDim)
                        .padding(.horizontal, Spacing.md)
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                }
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    liftRow(row)
                        .overlay(alignment: .top) {
                            if index > 0 { Rectangle().fill(SYN.border).frame(height: 0.5) }
                        }
                }
                if r.lifts.count > 5 {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { showAllLifts.toggle() }
                    } label: {
                        HStack(spacing: 5) {
                            Text(showAllLifts ? "Show fewer" : "Show all")
                                .font(.synText(13, weight: .semibold))
                            if !showAllLifts {
                                Text("\(r.lifts.count)").font(.synMono(13, weight: .semibold))
                            }
                        }
                        .foregroundStyle(SYN.cyan)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .top) { Rectangle().fill(SYN.border).frame(height: 0.5) }
                }
            }
            .progressCard()
        }
    }

    private func liftRow(_ row: LiftRow) -> some View {
        Button { sheet = .lift(row.id) } label: {
            HStack(spacing: Spacing.m) {
                Text(row.history.name)
                    .font(.synText(15, weight: .medium))
                    .foregroundStyle(SYN.text)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(row.latest.compact)
                    .font(.synMono(14, weight: .medium))
                    .foregroundStyle(SYN.textDim)
                    .lineLimit(1)
                trendGlyph(row.trend)
                    .frame(width: 28)
                LineGlyph(kind: .chevron, size: 12)
                    .foregroundStyle(SYN.textFaint)
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(row.history.name), \(row.latest.compact), \(trendLabel(row.trend))")
    }

    @ViewBuilder
    private func trendGlyph(_ trend: LiftTrend) -> some View {
        switch trend {
        case .up:   Text("↑").font(.synText(15, weight: .semibold)).foregroundStyle(SYN.green)
        case .down: Text("↓").font(.synText(15, weight: .semibold)).foregroundStyle(SYN.amber)
        case .flat: Text("→").font(.synText(15, weight: .semibold)).foregroundStyle(SYN.textDim)
        case .new:  Text("New").font(.synText(11, weight: .semibold)).foregroundStyle(SYN.textDim)
        }
    }

    private func trendLabel(_ trend: LiftTrend) -> String {
        switch trend {
        case .up:   return "up from last session"
        case .down: return "down from last session"
        case .flat: return "same as last session"
        case .new:  return "first session"
        }
    }

    // MARK: - Shared

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

    /// Geist 600 11, tracking 0.14em, uppercase, textDim.
    private func eyebrow(_ text: String) -> some View {
        Text(text)
            .font(.synText(11, weight: .semibold))
            .tracking(1.54)
            .textCase(.uppercase)
            .foregroundStyle(SYN.textDim)
            .lineLimit(1)
    }
}

private extension View {
    /// Progress cards: the same fill and hairline as Today's cards.
    func progressCard() -> some View {
        self
            .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(SYN.card))
            .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(SYN.border, lineWidth: 0.5))
    }
}

#Preview {
    ProgressScreen()
        .preferredColorScheme(.dark)
}
