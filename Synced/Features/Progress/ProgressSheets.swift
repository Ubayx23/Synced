import SwiftUI

/// Grabber, title, Done, and subtitle shared by both Progress sheets.
private struct SheetHeader<Accessory: View>: View {
    let title: String
    let subtitle: String
    let onDone: () -> Void
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(SYN.restDot)
                .frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.s)
            HStack {
                Text(title)
                    .font(.synText(20, weight: .semibold))
                    .foregroundStyle(SYN.text)
                    .lineLimit(1)
                Spacer(minLength: Spacing.m)
                accessory()
                Button("Done", action: onDone)
                    .font(.synText(15, weight: .semibold))
                    .foregroundStyle(SYN.cyan)
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
            }
            .padding(.top, 4)
            Text(subtitle)
                .font(.synText(13))
                .foregroundStyle(SYN.textDim)
        }
        .padding(.horizontal, Spacing.l)
    }
}

extension SheetHeader where Accessory == EmptyView {
    init(title: String, subtitle: String, onDone: @escaping () -> Void) {
        self.init(title: title, subtitle: subtitle, onDone: onDone) { EmptyView() }
    }
}

/// Three stats between hairlines.
private struct StatRow: View {
    struct Stat: Identifiable {
        let value: String
        let label: String
        var color: Color = SYN.text
        var weight: CGFloat = 1
        /// A dim second line under the value.
        var detail: String? = nil
        var id: String { label }
    }

    let stats: [Stat]
    let size: CGFloat

    var body: some View {
        GeometryReader { geo in
            let total = stats.map(\.weight).reduce(0, +)
            let spacing = Spacing.s * CGFloat(stats.count - 1)
            HStack(alignment: .top, spacing: Spacing.s) {
                ForEach(stats) { stat in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(stat.value)
                            .font(.synMono(size, weight: .semibold))
                            .foregroundStyle(stat.color)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        if let detail = stat.detail {
                            Text(detail)
                                .font(.synMono(11, weight: .medium))
                                .foregroundStyle(SYN.textDim)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .padding(.top, -2)
                        }
                        Text(stat.label)
                            .font(.synText(11))
                            .foregroundStyle(SYN.textFaint)
                            .lineLimit(1)
                    }
                    .frame(width: (geo.size.width - spacing) * stat.weight / total, alignment: .leading)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: size + 6 + 13 + 28 + (stats.contains { $0.detail != nil } ? 16 : 0))
        .overlay(alignment: .top) { Rectangle().fill(SYN.border).frame(height: 0.5) }
        .overlay(alignment: .bottom) { Rectangle().fill(SYN.border).frame(height: 0.5) }
        .padding(.horizontal, Spacing.l)
    }
}

// MARK: - Grade breakdown (C)

struct GradeBreakdownSheet: View {
    let report: ProgressReport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: "Grade breakdown", subtitle: "Sends · \(report.scope.label)", onDone: { dismiss() })

                StatRow(stats: [
                    .init(value: "\(report.totalSends)", label: "Sends"),
                    .init(value: report.topGrade.map { "V\($0)" } ?? "0", label: "Top grade", color: SYN.cyan),
                    .init(value: report.mostSent.map { "V\($0)" } ?? "0", label: "Most sent"),
                ], size: 22)
                .padding(.top, 18)

                if let top = report.topGrade {
                    let most = max(1, report.sendCounts.values.max() ?? 1)
                    VStack(spacing: Spacing.s) {
                        ForEach((0...top).reversed(), id: \.self) { grade in
                            row(grade: grade, count: report.sendCounts[grade] ?? 0, most: most, isTop: grade == top)
                        }
                    }
                    .padding(.horizontal, Spacing.l)
                    .padding(.top, 22)
                } else {
                    Text("No sends in this range yet.")
                        .font(.synText(15, weight: .medium))
                        .foregroundStyle(SYN.textDim)
                        .padding(.horizontal, Spacing.l)
                        .padding(.top, 22)
                }

                Text("Each row counts every send at that grade.")
                    .font(.synText(12))
                    .foregroundStyle(SYN.textFaint)
                    .padding(.horizontal, Spacing.l)
                    .padding(.top, 18)
            }
            .padding(.bottom, 34)
        }
        .scrollIndicators(.hidden)
    }

    private func row(grade: Int, count: Int, most: Int, isTop: Bool) -> some View {
        HStack(spacing: Spacing.m) {
            Text("V\(grade)")
                .font(.synMono(13, weight: .semibold))
                .foregroundStyle(isTop ? SYN.cyan : SYN.text)
                .frame(width: 30, alignment: .leading)
            GeometryReader { geo in
                let fraction = CGFloat(count) / CGFloat(most)
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isTop ? SYN.cyan : SYN.barNeutral)
                    .frame(width: count == 0 ? 0 : max(6, geo.size.width * fraction))
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 30)
            .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(SYN.text.opacity(0.025)))
            Text("\(count)")
                .font(.synMono(13, weight: .medium))
                .foregroundStyle(count > 0 ? SYN.textDim : SYN.textFaint)
                .frame(width: 26, alignment: .trailing)
        }
        .frame(height: 30)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Lift history (D)

struct LiftHistorySheet: View {
    let report: ProgressReport
    let history: ExerciseHistory
    let onHide: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDelete = false

    /// Sessions in range, newest first; the latest one when none are.
    private var sessions: [ExerciseSessionSets] {
        let ranged = history.sessions(since: report.rangeStart)
        return ranged.isEmpty ? Array(history.sessions.prefix(1)) : ranged
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(
                    title: history.name,
                    subtitle: "Top set per session · \(report.scope.label) · lbs",
                    onDone: { dismiss() }
                ) {
                    Menu {
                        Button("Hide", systemImage: "eye.slash") {
                            onHide()
                            dismiss()
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            confirmingDelete = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(SYN.textDim)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("More")
                }

                StatRow(stats: stats, size: 18)
                    .padding(.top, 18)

                bars
                    .padding(.horizontal, Spacing.l)
                    .padding(.top, Spacing.l)

                Text("Sessions")
                    .font(.synText(11, weight: .semibold))
                    .tracking(1.54)
                    .textCase(.uppercase)
                    .foregroundStyle(SYN.textDim)
                    .padding(.horizontal, Spacing.l)
                    .padding(.top, 28)
                    .padding(.bottom, 6)

                VStack(spacing: 0) {
                    ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                        sessionRow(session)
                            .overlay(alignment: .top) {
                                if index > 0 { Rectangle().fill(SYN.border).frame(height: 0.5) }
                            }
                    }
                }
                .padding(.horizontal, Spacing.l)
            }
            .padding(.bottom, 34)
        }
        .scrollIndicators(.hidden)
        .deleteExerciseConfirmation(
            history: confirmingDelete ? history : nil,
            onCancel: { confirmingDelete = false },
            onConfirm: {
                confirmingDelete = false
                onDelete()
                dismiss()
            }
        )
    }

    private var stats: [StatRow.Stat] {
        let latest = sessions.first?.top
        let first = sessions.last?.top
        var change = StatRow.Stat(value: "First log", label: "Change", color: SYN.textDim, weight: 1.3)
        if sessions.count >= 2, let latest, let first, let oldest = sessions.last {
            let delta = latest.scoreChange(since: first)
            change = StatRow.Stat(
                value: latest.scoreChangeText(since: first),
                label: "Since \(oldest.date.shortDayLabel)",
                color: delta > 0 ? SYN.green : delta < 0 ? SYN.amber : SYN.textDim,
                weight: 1.3,
                detail: latest.tradeOff(since: first)
            )
        }
        return [
            .init(value: latest?.compact ?? "-", label: "Latest top set", weight: 1.1),
            change,
            .init(value: "\(sessions.count)", label: "Sessions", weight: 0.8),
        ]
    }

    /// Up to eight most recent sessions in range, oldest on the left, at a
    /// fixed width so a few sessions don't stretch. Heights scale from 70%
    /// of the lowest score in view, so small gains look small; the highest
    /// bar is 92pt. Labels show the real set, with the estimate under the
    /// date.
    private var bars: some View {
        let shown = Array(sessions.prefix(8).reversed())
        let scores = shown.compactMap(\.top?.score)
        let high = scores.max() ?? 0
        let base = (scores.min() ?? 0) * 0.7
        return VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(shown.enumerated()), id: \.element.id) { index, session in
                    let isLatest = index == shown.count - 1
                    let score = session.top?.score ?? base
                    let height = high > base ? 92 * (score - base) / (high - base) : 92
                    VStack(spacing: 6) {
                        Text(session.top?.tight ?? "")
                            .font(.synMono(9.5, weight: .medium))
                            .foregroundStyle(isLatest ? SYN.cyan : SYN.textDim)
                            .fixedSize()
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(isLatest ? SYN.cyan : SYN.barNeutral)
                            .frame(width: 28, height: max(4, height))
                        VStack(spacing: 3) {
                            Text(session.date.formatted(.dateTime.month(.defaultDigits).day()))
                                .font(.synMono(9.5))
                                .foregroundStyle(SYN.textFaint)
                            Text(session.top.flatMap { $0.isBodyweight ? nil : "≈\(Int($0.e1RM.rounded()))" } ?? " ")
                                .font(.synMono(9))
                                .foregroundStyle(SYN.textFaint.opacity(0.7))
                        }
                        .fixedSize()
                    }
                    .frame(width: 28)
                }
            }
            .frame(height: 168, alignment: .bottomLeading)

            if shown.count == 1 {
                Text("Log it again to see a trend.")
                    .font(.synText(13))
                    .foregroundStyle(SYN.textDim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Date, then the top set in text color and the other sets dimmed.
    private func sessionRow(_ session: ExerciseSessionSets) -> some View {
        let sets = session.topFirst
        return HStack(spacing: Spacing.m) {
            Text(session.date.shortDayLabel)
                .font(.synMono(13))
                .foregroundStyle(SYN.textDim)
                .frame(width: 52, alignment: .leading)
            (Text(sets.first?.compact ?? "").foregroundColor(SYN.text)
             + Text(sets.dropFirst().map { " · \($0.compact)" }.joined()).foregroundColor(SYN.textDim))
                .font(.synMono(13, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }
        .frame(height: 46)
    }
}

// MARK: - Hidden exercises

/// Exercises hidden from Progress, each with Unhide.
struct HiddenExercisesSheet: View {
    let histories: [ExerciseHistory]
    let onUnhide: (ExerciseHistory) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(
                    title: "Hidden",
                    subtitle: "Hidden from Improving, Lifts, and suggestions. History is kept.",
                    onDone: { dismiss() }
                )

                VStack(spacing: 0) {
                    if histories.isEmpty {
                        Text("Nothing hidden.")
                            .font(.synText(15, weight: .medium))
                            .foregroundStyle(SYN.textDim)
                            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    }
                    ForEach(Array(histories.enumerated()), id: \.element.id) { index, history in
                        HStack(spacing: Spacing.m) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(history.name)
                                    .font(.synText(15, weight: .medium))
                                    .foregroundStyle(SYN.text)
                                    .lineLimit(1)
                                Text("\(history.sessions.count) \(history.sessions.count == 1 ? "session" : "sessions")")
                                    .font(.synText(12))
                                    .foregroundStyle(SYN.textFaint)
                            }
                            Spacer(minLength: 0)
                            Button("Unhide") { onUnhide(history) }
                                .font(.synText(13, weight: .semibold))
                                .foregroundStyle(SYN.cyan)
                                .buttonStyle(.plain)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .frame(height: 60)
                        .overlay(alignment: .top) {
                            if index > 0 { Rectangle().fill(SYN.border).frame(height: 0.5) }
                        }
                    }
                }
                .padding(.horizontal, Spacing.l)
                .padding(.top, 18)
            }
            .padding(.bottom, 34)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Delete confirmation

extension View {
    /// "Delete all Bench press history?" Shown while `history` is non-nil.
    func deleteExerciseConfirmation(
        history: ExerciseHistory?,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void
    ) -> some View {
        confirmationDialog(
            history.map { "Delete all \($0.name) history?" } ?? "",
            isPresented: Binding(get: { history != nil }, set: { if !$0 { onCancel() } }),
            titleVisibility: .visible,
            presenting: history
        ) { _ in
            Button("Delete", role: .destructive, action: onConfirm)
            Button("Cancel", role: .cancel, action: onCancel)
        } message: { history in
            let count = history.sessions.count
            Text("This removes it from \(count) \(count == 1 ? "session" : "sessions") and can't be undone.")
        }
    }
}
