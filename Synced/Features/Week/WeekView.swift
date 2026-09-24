import SwiftUI

/// Main screen after auth: the current Monday to Sunday week as seven rows.
/// Tap a row to plan a session for that day, tap a session to log or edit
/// it, or use Log now to record a session without planning it first.
struct WeekView: View {
    @State private var store = WeekStore()
    @State private var planTarget: PlanTarget?
    @State private var logTarget: LogTarget?
    @State private var showingProfile = false

    private let days = WeekStore.weekDays()
    private let rowGap = Spacing.s
    private let minRowHeight: CGFloat = 64

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.top, Spacing.md)
                    .padding(.bottom, statusLine == nil ? Spacing.lg : Spacing.s)

                if let statusLine {
                    statusLine
                        .padding(.bottom, Spacing.md)
                        .transition(.opacity)
                }

                GeometryReader { proxy in
                    ScrollView {
                        VStack(spacing: rowGap) {
                            ForEach(days, id: \.self) { day in
                                DayRow(
                                    day: day,
                                    sessions: store.sessions(on: day),
                                    height: rowHeight(for: proxy.size.height),
                                    onPlan: { planTarget = PlanTarget(day: day) },
                                    onOpen: { logTarget = LogTarget(session: $0) }
                                )
                            }
                        }
                        .padding(.bottom, Spacing.md)
                    }
                    .scrollIndicators(.hidden)
                    .scrollBounceBehavior(.basedOnSize)
                    .refreshable { await store.load(week: days) }
                }
            }
            .padding(.horizontal, Spacing.pageH)
        }
        .task { await store.load(week: days) }
        .sheet(item: $planTarget) { target in
            PlanSessionSheet(day: target.day, store: store)
        }
        .sheet(item: $logTarget) { target in
            LogSessionSheet(session: target.session, store: store)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileSheet()
        }
    }

    /// Rows share the available height so the week fills the screen, and
    /// scroll once a busy week needs more room.
    private func rowHeight(for available: CGFloat) -> CGFloat {
        let fitted = (available - Spacing.md - rowGap * 6) / 7
        return max(minRowHeight, fitted)
    }

    // MARK: - Status line

    /// A failed fetch shows an error with Retry. A week that loaded with no
    /// sessions gets a calm prompt instead; it is not an error.
    private var statusLine: AnyView? {
        switch store.loadState {
        case .failed(let message):
            return AnyView(
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.s) {
                        Text("Couldn't load this week.")
                            .font(.synText(13))
                            .foregroundStyle(SYN.red)
                        Button("Retry") {
                            Task { await store.load(week: days) }
                        }
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
            )
        case .loaded where store.sessions.isEmpty:
            return AnyView(
                Text("Plan your week to get started.")
                    .font(.synText(13))
                    .foregroundStyle(SYN.textDim)
            )
        default:
            return nil
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                EyebrowText(text: "This week")
                    .foregroundStyle(SYN.textFaint)

                Spacer()

                // Full 44pt hit target without inflating the eyebrow row.
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

            HStack(alignment: .center, spacing: Spacing.md) {
                Text(weekRangeLabel)
                    .font(.synDisplay(28, weight: .bold))
                    .foregroundStyle(SYN.text)
                    .kerning(-0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)

                logNowButton
            }
        }
    }

    private var logNowButton: some View {
        Button { logTarget = LogTarget(session: nil) } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                Text("Log now")
                    .font(.synText(15, weight: .semibold))
            }
            .foregroundStyle(SYN.bg)
            .padding(.horizontal, Spacing.md)
            .frame(height: 40)
            .background(Capsule().fill(SYN.cyan))
            .shadow(color: SYN.cyan.opacity(0.35), radius: 12)
        }
        .buttonStyle(.plain)
    }

    /// "Sep 22 to 28", or "Sep 29 to Oct 5" when the week crosses a month.
    private var weekRangeLabel: String {
        guard let first = days.first, let last = days.last else { return "" }
        let cal = WeekStore.calendar
        let start = first.formatted(.dateTime.month(.abbreviated).day())
        let sameMonth = cal.component(.month, from: first) == cal.component(.month, from: last)
        let end = sameMonth
            ? last.formatted(.dateTime.day())
            : last.formatted(.dateTime.month(.abbreviated).day())
        return "\(start) to \(end)"
    }
}

private struct PlanTarget: Identifiable {
    let day: Date
    var id: Date { day }
}

/// A nil session opens the log sheet as a fresh log for today.
private struct LogTarget: Identifiable {
    let session: Session?
    let id = UUID()
}

// MARK: - Day row

private struct DayRow: View {
    let day: Date
    let sessions: [Session]
    let height: CGFloat
    let onPlan: () -> Void
    let onOpen: (Session) -> Void

    private var cal: Calendar { WeekStore.calendar }
    private var isToday: Bool { cal.isDateInToday(day) }
    private var isPast: Bool { day < cal.startOfDay(for: Date()) }

    private var dateColor: Color {
        if isToday { return SYN.cyan }
        return isPast ? SYN.textFaint : SYN.text
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(spacing: 2) {
                Text(day.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.synText(11, weight: .semibold))
                    .tracking(1.0)
                    .textCase(.uppercase)
                    .foregroundStyle(isToday ? SYN.cyan : SYN.textFaint)
                Text(day.formatted(.dateTime.day()))
                    .font(.synMono(22, weight: .medium))
                    .foregroundStyle(dateColor)
            }
            .frame(width: 44)

            Rectangle()
                .fill(SYN.border)
                .frame(width: 1)
                .padding(.vertical, Spacing.m)

            HStack(spacing: Spacing.s) {
                ForEach(sessions) { session in
                    SessionChip(session: session, showsLabel: sessions.count <= 2) {
                        onOpen(session)
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "plus")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(sessions.isEmpty ? SYN.textDim : SYN.textFaint)
                .frame(width: 32, height: 32)
                .background(Circle().stroke(SYN.border, lineWidth: 1))
        }
        .padding(.horizontal, Spacing.md)
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(SYN.surface.opacity(isToday ? 1 : 0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(isToday ? SYN.cyan.opacity(0.45) : SYN.border, lineWidth: 1)
        )
        .shadow(color: isToday ? SYN.cyan.opacity(0.18) : .clear, radius: 14)
        .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .onTapGesture(perform: onPlan)
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Plan a session", onPlan)
        .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).month().day()))
    }
}

// MARK: - Session chip

/// Planned sessions are outlined in the type's color. Logged sessions are
/// filled and swap the type name for what was done (grade or focus), with a
/// small dot in the rating's color.
private struct SessionChip: View {
    let session: Session
    let showsLabel: Bool
    let action: () -> Void

    private var logged: Bool { !session.isPlanned }

    /// Logged rest stays subtle; logged climb and lift fill with their color.
    private var fill: Color {
        guard logged else { return session.type.color.opacity(0.08) }
        return session.type == .rest ? SYN.textDim.opacity(0.25) : session.type.color
    }

    private var foreground: Color {
        guard logged else { return session.type.color }
        return session.type == .rest ? SYN.text : SYN.bg
    }

    /// In compact chips a logged climb shows its grade instead of the icon,
    /// since the grade already says climb.
    private var showsGradeOnly: Bool {
        !showsLabel && logged && session.type == .climb && session.topGrade != nil
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if !showsGradeOnly {
                    Image(systemName: session.type.symbol)
                        .font(.system(size: 13, weight: .semibold))
                }
                if showsLabel || showsGradeOnly {
                    label
                }
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, showsLabel || showsGradeOnly ? Spacing.m : 0)
            .frame(minWidth: 32, minHeight: 32)
            .background(Capsule().fill(fill))
            .overlay(Capsule().stroke(session.type.color.opacity(logged ? 0 : 0.7), lineWidth: 1))
            .overlay(alignment: .topTrailing) {
                if logged, let rating = session.rating {
                    Circle()
                        .fill(Session.ratingColor(rating))
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(SYN.bg, lineWidth: 2))
                        .offset(x: 1, y: -1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
    }

    /// Primary detail (top grade or first focus) plus a dimmer count of the
    /// rest: "V4 ×5" for five sends, "Chest +1" for two muscle groups.
    @ViewBuilder
    private var label: some View {
        if logged, let detail = session.detail {
            HStack(spacing: 3) {
                Text(detail)
                    .font(session.type == .climb
                          ? .synMono(13, weight: .semibold)
                          : .synText(13, weight: .semibold))
                if let extra = session.detailExtra {
                    Text(extra)
                        .font(.synMono(11, weight: .medium))
                        .opacity(0.7)
                }
            }
        } else {
            Text(session.type.title)
                .font(.synText(13, weight: .semibold))
        }
    }

    private var accessibilityText: String {
        var parts = ["\(logged ? "Logged" : "Planned") \(session.type.title)"]
        if logged, let spoken = session.spokenDetail { parts.append(spoken) }
        if logged, let rating = session.rating { parts.append("rated \(rating) of 5") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Session type display

extension SessionType {
    var title: String {
        switch self {
        case .climb: return "Climb"
        case .lift:  return "Lift"
        case .rest:  return "Rest"
        }
    }

    var symbol: String {
        switch self {
        case .climb: return "figure.climbing"
        case .lift:  return "dumbbell.fill"
        case .rest:  return "moon.fill"
        }
    }

    var color: Color {
        switch self {
        case .climb: return SYN.cyan
        case .lift:  return SYN.green
        case .rest:  return SYN.textDim
        }
    }
}

extension MuscleGroup {
    var title: String {
        switch self {
        case .chest:     return "Chest"
        case .back:      return "Back"
        case .shoulders: return "Shoulders"
        case .arms:      return "Arms"
        case .legs:      return "Legs"
        case .fullBody:  return "Full body"
        }
    }
}

extension Session {
    /// What was done: the top grade for a climb, the first focus (grid
    /// order) for a lift.
    var detail: String? {
        switch type {
        case .climb: return topGrade.map { "V\($0)" }
        case .lift:  return muscles.first?.title
        case .rest:  return nil
        }
    }

    /// Secondary count shown after `detail`, only when there is more than one.
    var detailExtra: String? {
        switch type {
        case .climb: return grades.count > 1 ? "×\(grades.count)" : nil
        case .lift:  return muscles.count > 1 ? "+\(muscles.count - 1)" : nil
        case .rest:  return nil
        }
    }

    var spokenDetail: String? {
        guard let detail else { return nil }
        switch type {
        case .climb:
            return grades.count > 1 ? "top grade \(detail), \(grades.count) sends" : detail
        case .lift:
            return muscles.map(\.title).joined(separator: ", ")
        case .rest:
            return nil
        }
    }

    /// Shared rating palette: 1 red, 2 amber, 3 neutral, 4 green, 5 cyan.
    static func ratingColor(_ rating: Int) -> Color {
        switch rating {
        case 1:  return SYN.red
        case 2:  return SYN.amber
        case 3:  return SYN.textDim
        case 4:  return SYN.green
        default: return SYN.cyan
        }
    }
}

#Preview {
    WeekView()
        .environment(SessionStore())
        .preferredColorScheme(.dark)
}
