import SwiftUI

/// Home tab. Today's session up top, a swipeable Monday to Sunday strip for
/// planning, then recovery, the last session, tomorrow, the last note, and
/// this week's totals. Laid out with fixed heights from the "Today Final"
/// mockup so it fills a 393 x 852 screen exactly; smaller screens scroll.
struct TodayView: View {
    @State private var store = TodayStore()
    /// Sessions for the strip when it shows a week other than this one.
    @State private var stripStore = WeekStore()
    @State private var recovery = RecoveryStore()

    @State private var today = Date()
    /// 0 is the current week in the strip; -1 last week, 1 next week.
    @State private var weekOffset = 0
    /// Which way the strip last paged, for the slide direction.
    @State private var pagedForward = true

    @State private var planTarget: TodayPlanTarget?
    @State private var logTarget: TodayLogTarget?
    @State private var changeTarget: Session?
    @State private var dayChoice: DayChoice?
    @State private var showingProfile = false
    @State private var showingRecovery = false
    @State private var changeError: String?

    @Environment(\.scenePhase) private var scenePhase
    @State private var router = AppRouter.shared

    private var cal: Calendar { WeekStore.calendar }

    private var tomorrow: Date {
        cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: today)) ?? today
    }

    private var stripDays: [Date] {
        let anchor = cal.date(byAdding: .weekOfYear, value: weekOffset, to: today) ?? today
        return WeekStore.weekDays(containing: anchor)
    }

    var body: some View {
        GeometryReader { geo in
            // Always a ScrollView so pull to refresh works; at 393 x 852 the
            // content is exactly the visible height, so nothing scrolls.
            ScrollView {
                content(topInset: max(0, TodayLayout.headerTop - geo.safeAreaInsets.top))
                    .frame(minHeight: geo.size.height, alignment: .top)
            }
            .scrollIndicators(.hidden)
            .refreshable { await reload() }
        }
        .background(SYN.bg.ignoresSafeArea())
        .task { await reload() }
        .task(id: weekOffset) {
            guard weekOffset != 0 else { return }
            await stripStore.load(week: stripDays)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                today = Date()
                Task { await reload() }
            }
        }
        // A tapped reminder, whether the app was running or cold launched.
        .onChange(of: router.pendingLogFromReminder) { _, pending in
            if pending { Task { await openLogFromReminder() } }
        }
        .onAppear {
            if router.pendingLogFromReminder { Task { await openLogFromReminder() } }
        }
        .sheet(item: $planTarget, onDismiss: refresh) { target in
            PlanSessionSheet(day: target.day, store: target.store)
        }
        .sheet(item: $logTarget, onDismiss: refresh) { target in
            LogSessionSheet(session: target.session, store: target.store, focusNotesOnAppear: target.focusNotes)
        }
        .sheet(isPresented: $showingRecovery, onDismiss: refresh) {
            RecoveryView(onClose: { showingRecovery = false })
                .presentationDragIndicator(.visible)
                .presentationBackground(SYN.bg)
                .presentationCornerRadius(Radius.card * 2)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileSheet()
        }
        .confirmationDialog(
            "Change to",
            isPresented: Binding(get: { changeTarget != nil }, set: { if !$0 { changeTarget = nil } }),
            titleVisibility: .visible,
            presenting: changeTarget
        ) { session in
            ForEach(SessionType.allCases.filter { $0 != session.type }) { type in
                Button(type.title) { change(session, to: type) }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            dayChoice.map { $0.day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()) } ?? "",
            isPresented: Binding(get: { dayChoice != nil }, set: { if !$0 { dayChoice = nil } }),
            titleVisibility: .visible,
            presenting: dayChoice
        ) { choice in
            ForEach(choice.sessions) { session in
                Button("\(session.isPlanned ? "Planned" : "Logged") \(session.type.title.lowercased())") {
                    openLog(session)
                }
            }
            Button("Plan a session") { openPlan(choice.day) }
            Button("Cancel", role: .cancel) {}
        }
        .alert(
            "Couldn't change that session. Try again.",
            isPresented: Binding(get: { changeError != nil }, set: { if !$0 { changeError = nil } })
        ) {
            Button("OK", role: .cancel) {}
        }
    }

    /// The mockup's vertical stack, top to bottom. The tab bar sits below,
    /// supplied by MainTabView.
    private func content(topInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            header
                .padding(.top, topInset)

            strip
                .padding(.top, Spacing.lg)

            hero
                .padding(.horizontal, Spacing.pageH)
                .padding(.top, TodayLayout.heroGap)

            HStack(spacing: Spacing.m) {
                recoveryCard
                lastCard
            }
            .padding(.horizontal, Spacing.pageH)
            .padding(.top, Spacing.l)

            tomorrowCard
                .padding(.horizontal, Spacing.pageH)
                .padding(.top, Spacing.md)

            noteCard
                .padding(.horizontal, Spacing.pageH)
                .padding(.top, Spacing.m)

            weekStatsCard
                .padding(.horizontal, Spacing.pageH)
                .padding(.top, Spacing.m)

            Spacer(minLength: TodayLayout.tabBarGap)
        }
    }

    // MARK: - Loading

    @MainActor
    private func reload() async {
        await store.load(today: today)
        if weekOffset != 0 { await stripStore.load(week: stripDays) }
        await recovery.load()
    }

    private func refresh() {
        Task { await reload() }
    }

    /// Sheets write to the store that holds the day, so the change shows
    /// at once in whichever view reads it.
    private func store(for day: Date) -> WeekStore {
        let inRange = TodayStore.loadRange(today: today).contains { cal.isDate($0, inSameDayAs: day) }
        return inRange ? store.week : stripStore
    }

    private func sessions(on day: Date) -> [Session] {
        store(for: day).sessions(on: day)
    }

    // MARK: - Routing

    private func openLog(_ session: Session?, focusNotes: Bool = false) {
        let day = session?.date ?? today
        logTarget = TodayLogTarget(session: session, store: store(for: day), focusNotes: focusNotes)
    }

    private func openPlan(_ day: Date) {
        planTarget = TodayPlanTarget(day: day, store: store(for: day))
    }

    /// Empty day: plan it, or log it when it is today. One session: open
    /// it. Several: pick one, or plan another.
    private func openDay(_ day: Date) {
        let list = sessions(on: day)
        switch list.count {
        case 0:
            if cal.isDate(day, inSameDayAs: today) { openLog(nil) } else { openPlan(day) }
        case 1:
            openLog(list[0])
        default:
            dayChoice = DayChoice(day: day, sessions: list)
        }
    }

    private func change(_ session: Session, to type: SessionType) {
        Task {
            do {
                try await store(for: session.date).changeType(of: session, to: type)
                await reload()
            } catch {
                changeError = error.localizedDescription
            }
        }
    }

    /// Opens the Log sheet for today: today's first planned session if
    /// there is one, otherwise a fresh log.
    @MainActor
    private func openLogFromReminder() async {
        router.pendingLogFromReminder = false
        planTarget = nil
        showingProfile = false
        showingRecovery = false
        logTarget = nil
        today = Date()
        weekOffset = 0
        await store.load(today: today)
        let planned = store.sessions(on: today).first { $0.isPlanned }
        logTarget = TodayLogTarget(session: planned, store: store.week, focusNotes: false)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                eyebrow("Today")
                Text(today.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.synMono(15))
                    .kerning(-0.15)
                    .foregroundStyle(SYN.text)
            }

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
        .padding(.horizontal, Spacing.pageH)
        .frame(height: TodayLayout.header)
    }

    /// No names are stored, so the avatar shows the first two letters of
    /// the email's local part.
    private var initials: String {
        let local = supabase.auth.currentUser?.email?.split(separator: "@").first.map(String.init) ?? ""
        let letters = local.filter(\.isLetter)
        return String((letters.isEmpty ? local : letters).prefix(2)).uppercased()
    }

    // MARK: - Day strip

    private var strip: some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                ForEach(stripDays, id: \.self) { day in
                    DayCell(
                        day: day,
                        today: today,
                        sessions: sessions(on: day),
                        onTap: { openDay(day) },
                        onPlan: { openPlan(day) }
                    )
                }
            }
            .padding(.horizontal, TodayLayout.stripInset)
            .id(weekOffset)
            .transition(.push(from: pagedForward ? .trailing : .leading))
            .frame(maxWidth: .infinity)
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        guard abs(value.translation.width) > 30,
                              abs(value.translation.width) > abs(value.translation.height) else { return }
                        page(value.translation.width < 0 ? 1 : -1)
                    }
            )

            Spacer(minLength: 0)

            stripCaption
        }
        .frame(height: TodayLayout.strip)
    }

    private func page(_ step: Int) {
        pagedForward = step > 0
        withAnimation(.easeOut(duration: 0.3)) { weekOffset += step }
    }

    /// "4 of 7 trained this week", from logged climbs and lifts in the
    /// week the strip shows. Off the current week, a Today link returns.
    private var stripCaption: some View {
        let trained = stripDays.filter { day in sessions(on: day).contains(where: \.countsAsTrained) }.count
        return HStack(spacing: Spacing.s) {
            (Text("\(trained)").font(.synMono(12))
             + Text(" of ")
             + Text("7").font(.synMono(12))
             + Text(weekOffset == 0 ? " trained this week" : " trained that week"))
                .font(.synText(12))
                .foregroundStyle(SYN.textDim)
                .contentTransition(.numericText())

            if weekOffset != 0 {
                Button {
                    pagedForward = weekOffset < 0
                    withAnimation(.easeOut(duration: 0.3)) { weekOffset = 0 }
                } label: {
                    Text("Today")
                        .font(.synText(12, weight: .semibold))
                        .foregroundStyle(SYN.cyan)
                        .padding(.horizontal, Spacing.s)
                        .frame(height: 22)
                        .overlay(Capsule().stroke(SYN.cyan.opacity(0.5), lineWidth: 1))
                        .padding(.vertical, -Spacing.xs)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Go to this week")
            }
        }
        .frame(height: 14)
    }

    // MARK: - Hero

    private var hero: some View {
        let session = store.heroSession(today: today)
        let planned = session?.isPlanned == true
        let eyebrowText = session.map { "\($0.type.title) session" } ?? "Today"
        let subtitle: String = {
            guard let session else { return "Nothing planned yet" }
            return session.isPlanned ? "Planned for today" : "Logged today"
        }()
        let buttonTitle: String = {
            guard let session else { return "Log a session" }
            return session.isPlanned ? "Log \(session.type.title.lowercased()) session" : "Edit session"
        }()

        return ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 14) {
                    TypeGlyph(type: session?.type)
                        .foregroundStyle(SYN.text)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(SYN.surfaceHi))
                    VStack(alignment: .leading, spacing: 5) {
                        eyebrow(eyebrowText)
                        Text(subtitle)
                            .font(.synText(18, weight: .medium))
                            .kerning(-0.36)
                            .foregroundStyle(SYN.text)
                    }
                }
                Spacer(minLength: 0)
                Button { openLog(session) } label: {
                    Text(buttonTitle)
                        .font(.synText(16, weight: .bold))
                        .kerning(-0.16)
                        .foregroundStyle(SYN.bg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: Radius.button, style: .continuous).fill(SYN.cyan))
                        .contentShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
                }
                .buttonStyle(PressDimStyle())
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: TodayLayout.hero)
            .contentShape(RoundedRectangle(cornerRadius: Radius.hero, style: .continuous))
            .onTapGesture { openLog(session) }

            if planned, let session {
                Button { changeTarget = session } label: {
                    Text("Change")
                        .font(.synText(12, weight: .medium))
                        .foregroundStyle(SYN.cyan)
                        .padding(18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Change today's session type")
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.hero, style: .continuous)
                .fill(SYN.card)
                .shadow(color: SYN.cyan.opacity(0.12), radius: 16)
        )
        // Half point cyan edge just outside the card.
        .overlay(
            RoundedRectangle(cornerRadius: Radius.hero + 0.25, style: .continuous)
                .stroke(SYN.cyan.opacity(0.25), lineWidth: 0.5)
                .padding(-0.25)
                .allowsHitTesting(false)
        )
        // Radial bloom 22 past the sides and 28 past the top and bottom.
        .background(
            EllipticalGradient(
                colors: [SYN.cyan.opacity(0.15), SYN.cyan.opacity(0)],
                center: .center,
                startRadiusFraction: 0,
                endRadiusFraction: 0.5
            )
            .padding(.horizontal, -22)
            .padding(.vertical, -28)
            .blur(radius: 8)
            .allowsHitTesting(false)
        )
    }

    // MARK: - Recovery and Last

    private var recoveryCard: some View {
        Button { showingRecovery = true } label: {
            smallCard(title: "Recovery") {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text(recovery.loadState == .loaded ? "\(recovery.readyCount)" : "-")
                        .font(.synMono(30, weight: .medium))
                        .kerning(-0.6)
                        .foregroundStyle(SYN.cyan)
                        .contentTransition(.numericText())
                    Text("/ \(MuscleGroup.allCases.count)")
                        .font(.synMono(15))
                        .foregroundStyle(SYN.textDim)
                }
                .frame(height: 30)
                Text("ready")
                    .font(.synText(13))
                    .foregroundStyle(SYN.textDim)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Recovery, \(recovery.readyCount) of \(MuscleGroup.allCases.count) muscle groups ready")
    }

    private var lastCard: some View {
        let last = store.lastSession
        return Button { openLog(last) } label: {
            smallCard(title: "Last") {
                Text(last?.type.title ?? "None yet")
                    .font(.synDisplay(26, weight: .medium))
                    .kerning(-0.52)
                    .foregroundStyle(last == nil ? SYN.textDim : SYN.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(height: 30)
                Text(last?.date.relativeDayLabel(today: today) ?? "Log your first session")
                    .font(.synText(13))
                    .foregroundStyle(SYN.textDim)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    private func smallCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            eyebrow(title)
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 5) {
                content()
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: TodayLayout.pair)
        .overlay(alignment: .topTrailing) {
            LineGlyph(kind: .chevron, size: 14)
                .foregroundStyle(SYN.textFaint)
                .padding(14)
        }
        .todayCard()
    }

    // MARK: - Tomorrow

    private var tomorrowCard: some View {
        let session = store.tomorrowSession(today: today)
        return wideCard(title: "Tomorrow", height: TodayLayout.wide, action: { openPlan(tomorrow) }) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.m) {
                if let session {
                    (Text(session.type.title.uppercased())
                     + Text(session.muscles.isEmpty ? "" : " · \(session.muscles.map(\.title).joined(separator: " + "))")
                        .foregroundColor(SYN.textDim)
                        .font(.synText(15)))
                        .font(.synText(15, weight: .medium))
                        .kerning(-0.15)
                        .foregroundStyle(SYN.text)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if session.isPlanned {
                        Button { changeTarget = session } label: {
                            Text("Change")
                                .font(.synText(12, weight: .medium))
                                .foregroundStyle(SYN.textDim)
                                .padding(.vertical, Spacing.s)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, -Spacing.s)
                        .accessibilityLabel("Change tomorrow's session type")
                    }
                } else {
                    Text("Nothing planned")
                        .font(.synText(15, weight: .medium))
                        .kerning(-0.15)
                        .foregroundStyle(SYN.text)
                    Spacer(minLength: 0)
                    Text("Plan tomorrow →")
                        .font(.synText(12, weight: .medium))
                        .foregroundStyle(SYN.cyan)
                }
            }
        }
    }

    // MARK: - Last note

    @ViewBuilder
    private var noteCard: some View {
        if let session = store.lastSession, let note = store.lastNote {
            wideCard(
                title: "Last note · \(session.date.relativeDayLabel(today: today)) · \(session.type.title)",
                height: TodayLayout.wide,
                action: { openLog(session) }
            ) {
                Text(note)
                    .font(.synText(14))
                    .foregroundStyle(SYN.text)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        } else {
            // Same slot and height as a note. Opens today's session (or a
            // fresh one) at Notes, focused.
            wideCard(title: "Last note", height: TodayLayout.wide, action: { openLog(store.heroSession(today: today), focusNotes: true) }) {
                Text("Tap to add a note to today's session.")
                    .font(.synText(14))
                    .foregroundStyle(SYN.textDim)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - This week

    private var weekStatsCard: some View {
        let climbs = store.climbsThisWeek(today: today)
        let lifts = store.liftsThisWeek(today: today)
        let volume = Int(store.volumeThisWeek(today: today).rounded())
        return VStack(alignment: .leading, spacing: Spacing.s) {
            eyebrow("This week")
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                stat(climbs.formatted(), climbs == 1 ? "climb" : "climbs")
                separator
                stat(lifts.formatted(), lifts == 1 ? "lift" : "lifts")
                separator
                stat(volume.formatted(), "lbs volume")
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: TodayLayout.stats)
        .todayCard()
        .accessibilityElement(children: .combine)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(value)
                .font(.synMono(15, weight: .medium))
                .foregroundStyle(SYN.text)
                .contentTransition(.numericText())
            Text(label)
                .font(.synText(13))
                .foregroundStyle(SYN.textDim)
        }
    }

    private var separator: some View {
        Text("·")
            .font(.synText(13))
            .foregroundStyle(SYN.textFaint)
    }

    private func wideCard<Content: View>(
        title: String,
        height: CGFloat,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                eyebrow(title)
                content()
            }
            .padding(.horizontal, Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: height)
            .todayCard()
        }
        .buttonStyle(.plain)
    }

    /// Today's eyebrow: Geist 600 11, tracking 0.14em, textDim. Tighter
    /// than the shared EyebrowText, per the mockup.
    private func eyebrow(_ text: String) -> some View {
        Text(text)
            .font(.synText(11, weight: .semibold))
            .tracking(TodayLayout.eyebrowTracking)
            .textCase(.uppercase)
            .foregroundStyle(SYN.textDim)
            .lineLimit(1)
    }
}

// MARK: - Layout

/// Fixed heights and gaps from the "Today Final" mockup (pt). With the 85pt
/// tab bar they add up to 852.
private enum TodayLayout {
    /// Header top from the screen top: the mockup's 50pt status bar plus 12.
    static let headerTop: CGFloat = 62
    static let header: CGFloat = 48
    static let strip: CGFloat = 78
    static let hero: CGFloat = 160
    static let pair: CGFloat = 95
    static let wide: CGFloat = 64
    static let stats: CGFloat = 60
    static let heroGap: CGFloat = 26
    static let tabBarGap: CGFloat = 26
    static let stripInset: CGFloat = 18
    /// 0.14em at 11pt.
    static let eyebrowTracking: CGFloat = 1.54
}

// MARK: - Day cell

/// One day in the strip: letter, date, and one indicator for what happened.
/// Logged climb is a filled dot, logged lift a cyan ring, logged rest a
/// muted dot, a plan a dashed ring; nothing means untouched.
private struct DayCell: View {
    let day: Date
    let today: Date
    let sessions: [Session]
    let onTap: () -> Void
    let onPlan: () -> Void

    private var cal: Calendar { WeekStore.calendar }
    private var isToday: Bool { cal.isDate(day, inSameDayAs: today) }
    private var isFuture: Bool { day > cal.startOfDay(for: today) && !isToday }

    private enum Mark { case climb, lift, rest, planned }

    private var mark: Mark? {
        let logged = sessions.filter { !$0.isPlanned }
        if logged.contains(where: { $0.type == .climb }) { return .climb }
        if logged.contains(where: { $0.type == .lift }) { return .lift }
        if logged.contains(where: { $0.type == .rest }) { return .rest }
        return sessions.isEmpty ? nil : .planned
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                Text(day.formatted(.dateTime.weekday(.narrow)))
                    .font(.synText(11, weight: .medium))
                    .foregroundStyle(SYN.textDim)
                    .frame(height: 13)
                Text(day.formatted(.dateTime.day()))
                    .font(.synMono(15, weight: isToday ? .medium : .regular))
                    .foregroundStyle(isToday ? SYN.cyan : isFuture ? SYN.textDim : SYN.text)
                    .frame(height: 15)
                indicator
                    .frame(width: 6, height: 6)
            }
            // The mockup's 7/8 padding plus its 1pt border.
            .padding(.top, 8)
            .padding(.bottom, 9)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                    .strokeBorder(isToday ? SYN.cyan.opacity(0.5) : .clear, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { onPlan() } label: { Label("Plan a session", systemImage: "plus") }
        }
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var indicator: some View {
        switch mark {
        case .climb:
            Circle().fill(SYN.cyan)
        case .lift:
            Circle().strokeBorder(SYN.cyan, lineWidth: 1.5)
        case .rest:
            Circle().fill(SYN.restDot)
        case .planned:
            Circle()
                .inset(by: 0.75)
                .stroke(SYN.textDim, style: StrokeStyle(lineWidth: 1.3, dash: [1.6, 1.2]))
        case nil:
            Color.clear
        }
    }

    private var accessibilityText: String {
        let date = day.formatted(.dateTime.weekday(.wide).month().day())
        guard !sessions.isEmpty else { return "\(date), nothing planned" }
        let parts = sessions.map { "\($0.isPlanned ? "planned" : "logged") \($0.type.title.lowercased())" }
        return "\(date), \(parts.joined(separator: ", "))"
    }
}

// MARK: - Hero glyph

/// The hero tile's line icon: the mockup's mountain for climbs, SF line
/// symbols for lift and rest, a plus when nothing is planned.
private struct TypeGlyph: View {
    let type: SessionType?

    var body: some View {
        switch type {
        case .climb:
            LineGlyph(kind: .mountain, size: 22)
        case .lift:
            symbol("dumbbell")
        case .rest:
            symbol("moon")
        case nil:
            symbol("plus")
        }
    }

    private func symbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 18, weight: .regular))
    }
}
// MARK: - Targets

private struct TodayPlanTarget: Identifiable {
    let day: Date
    let store: WeekStore
    let id = UUID()
}

/// A nil session opens the Log sheet as a fresh log for today.
private struct TodayLogTarget: Identifiable {
    let session: Session?
    let store: WeekStore
    var focusNotes = false
    let id = UUID()
}

private struct DayChoice: Identifiable {
    let day: Date
    let sessions: [Session]
    var id: Date { day }
}

// MARK: - Styles

/// Dims the hero button while pressed.
private struct PressDimStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

private extension View {
    /// Every Today card: SYN.card fill with a 0.5pt inner border.
    func todayCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(SYN.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(SYN.border, lineWidth: 0.5)
            )
    }
}

#Preview {
    TodayView()
        .preferredColorScheme(.dark)
}
