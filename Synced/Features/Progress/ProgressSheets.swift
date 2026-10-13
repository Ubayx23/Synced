import SwiftUI

/// Grabber, title, Done, and subtitle shared by both Progress sheets.
private struct SheetHeader<Accessory: View>: View {
    let title: String
    let subtitle: String
    let onDone: () -> Void
    var doneTitle = "Done"
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
                Button(doneTitle, action: onDone)
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
    /// Every exercise, for spotting a rename that merges into another.
    let allHistories: [ExerciseHistory]
    let onHide: () -> Void
    let onDelete: () -> Void
    let onRename: (String) async throws -> Void
    /// New sets for one session, or nil to remove the exercise from it.
    let onEditSession: (ExerciseSessionSets, [LiftSet]?) async throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDelete = false
    @State private var renaming = false
    @State private var editing: ExerciseSessionSets?

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
                        Button("Edit name", systemImage: "pencil") {
                            renaming = true
                        }
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
                            .foregroundStyle(SYN.text)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(SYN.surfaceHi))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Edit, hide, or delete")
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
                        Button { editing = session } label: { sessionRow(session) }
                            .buttonStyle(.plain)
                            .accessibilityHint("Edit this session's sets")
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
        .sheet(isPresented: $renaming) {
            RenameExerciseSheet(history: history, allHistories: allHistories, onSave: onRename)
                .progressSubsheet(height: 330)
        }
        .sheet(item: $editing) { session in
            EditSessionExerciseSheet(name: history.name, session: session) { sets in
                try await onEditSession(session, sets)
            }
            .progressSubsheet(height: nil)
        }
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
    /// fixed width so a few sessions don't stretch. Heights scale from zero
    /// against the highest score in view (92pt), with an 8pt floor, so a 5%
    /// difference looks like 5%. Score is estimated 1RM, or reps for
    /// bodyweight. Labels show the real set, with the estimate under the
    /// date; a cyan PR tag marks a top set heavier than any earlier set.
    private var bars: some View {
        let shown = Array(sessions.prefix(8).reversed())
        let high = shown.compactMap(\.top?.score).max() ?? 0
        let prs = weightPRs
        return VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(shown.enumerated()), id: \.element.id) { index, session in
                    let isLatest = index == shown.count - 1
                    let score = session.top?.score ?? 0
                    let height = high > 0 ? 92 * score / high : 92
                    VStack(spacing: 6) {
                        if prs.contains(session.id) {
                            Text("PR")
                                .font(.synMono(9, weight: .semibold))
                                .foregroundStyle(SYN.cyan)
                                .fixedSize()
                                .accessibilityLabel("Weight PR")
                        }
                        Text(session.top?.tight ?? "")
                            .font(.synMono(9.5, weight: .medium))
                            .foregroundStyle(isLatest ? SYN.cyan : SYN.textDim)
                            .fixedSize()
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(isLatest ? SYN.cyan : SYN.barNeutral)
                            .frame(width: 28, height: max(8, height))
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

    /// Sessions whose top set is heavier than every set logged before it,
    /// across all of this exercise's history. The first session has
    /// nothing to beat, and bodyweight sets never count.
    private var weightPRs: Set<UUID> {
        var heaviest: Double?
        var ids: Set<UUID> = []
        for session in history.sessions.reversed() {
            if let top = session.top, !top.isBodyweight, let heaviest, top.weightLbs > heaviest {
                ids.insert(session.id)
            }
            let sessionMax = session.sets.map(\.weightLbs).max() ?? 0
            heaviest = max(heaviest ?? 0, sessionMax)
        }
        return ids
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
            LineGlyph(kind: .chevron, size: 12)
                .foregroundStyle(SYN.textFaint)
        }
        .frame(height: 46)
        .contentShape(Rectangle())
    }
}

// MARK: - Edit name

/// Renames an exercise on every session. A name that matches another
/// exercise merges the two after a confirmation.
struct RenameExerciseSheet: View {
    let history: ExerciseHistory
    let allHistories: [ExerciseHistory]
    let onSave: (String) async throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var saving = false
    @State private var mergeTarget: ExerciseHistory?
    @State private var failed = false

    init(history: ExerciseHistory, allHistories: [ExerciseHistory], onSave: @escaping (String) async throws -> Void) {
        self.history = history
        self.allHistories = allHistories
        self.onSave = onSave
        _name = State(initialValue: history.name)
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(
                title: "Edit name",
                subtitle: "Renames it on every session.",
                onDone: { dismiss() },
                doneTitle: "Cancel"
            ) { EmptyView() }

            SpecInput(value: $name, placeholder: "Exercise name", autocap: .sentences, autoFocus: true)
                .padding(.horizontal, Spacing.l)
                .padding(.top, Spacing.l)

            if failed {
                Text("Couldn't save. Try again.")
                    .font(.synText(13))
                    .foregroundStyle(SYN.red)
                    .padding(.horizontal, Spacing.l)
                    .padding(.top, Spacing.s)
            }

            PrimaryButton(title: "Save", disabled: trimmed.isEmpty || trimmed == history.name || saving) {
                if let target = allHistories.first(where: { $0.id == trimmed.exerciseMatchKey && $0.id != history.id }) {
                    mergeTarget = target
                } else {
                    save()
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.top, Spacing.l)

            Spacer(minLength: 0)
        }
        .confirmationDialog(
            mergeTarget.map { "Merge into \($0.name)?" } ?? "",
            isPresented: Binding(get: { mergeTarget != nil }, set: { if !$0 { mergeTarget = nil } }),
            titleVisibility: .visible,
            presenting: mergeTarget
        ) { _ in
            Button("Merge") { save() }
            Button("Cancel", role: .cancel) { mergeTarget = nil }
        } message: { target in
            Text("\(history.name) and \(target.name) become one exercise with both histories. This can't be undone.")
        }
    }

    private func save() {
        saving = true
        failed = false
        Task {
            do {
                try await onSave(trimmed)
                dismiss()
            } catch {
                failed = true
            }
            saving = false
        }
    }
}

// MARK: - Edit one session

/// Edits one exercise's sets on one session, or removes the exercise from
/// that session. The session itself is never deleted.
struct EditSessionExerciseSheet: View {
    let name: String
    let session: ExerciseSessionSets
    /// New sets, or nil to remove the exercise from the session.
    let onSave: ([LiftSet]?) async throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var drafts: [ExerciseDraft]
    @State private var saving = false
    @State private var confirmingRemove = false
    @State private var failed = false

    init(name: String, session: ExerciseSessionSets, onSave: @escaping ([LiftSet]?) async throws -> Void) {
        self.name = name
        self.session = session
        self.onSave = onSave
        var draft = ExerciseDraft()
        draft.name = name
        draft.sets = session.sets.isEmpty ? [SetDraft()] : session.sets.map(SetDraft.init)
        _drafts = State(initialValue: [draft])
    }

    private var sets: [LiftSet] { drafts.first?.sets.compactMap(\.value) ?? [] }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SheetHeader(
                        title: name,
                        subtitle: "\(session.date.shortDayLabel) · lbs",
                        onDone: { dismiss() },
                        doneTitle: "Cancel"
                    ) { EmptyView() }

                    ExercisesEditor(exercises: $drafts, scrollProxy: proxy, setsOnly: true)
                        .padding(.horizontal, Spacing.l)
                        .padding(.top, Spacing.l)

                    if failed {
                        Text("Couldn't save. Try again.")
                            .font(.synText(13))
                            .foregroundStyle(SYN.red)
                            .padding(.horizontal, Spacing.l)
                            .padding(.top, Spacing.m)
                    }

                    PrimaryButton(title: "Save", disabled: sets.isEmpty || saving) {
                        save(sets)
                    }
                    .padding(.horizontal, Spacing.l)
                    .padding(.top, Spacing.l)

                    Button("Remove from this session") { confirmingRemove = true }
                        .font(.synText(15, weight: .medium))
                        .foregroundStyle(SYN.red)
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .disabled(saving)
                        .padding(.top, Spacing.s)
                }
                .padding(.bottom, 34)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .confirmationDialog(
            "Remove \(name) from this session?",
            isPresented: $confirmingRemove,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) { save(nil) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The session stays. Only this exercise is removed from it.")
        }
    }

    private func save(_ sets: [LiftSet]?) {
        saving = true
        failed = false
        Task {
            do {
                try await onSave(sets)
                dismiss()
            } catch {
                failed = true
            }
            saving = false
        }
    }
}

extension View {
    /// Presentation shared by the Progress sheets: card fill, 24pt corners,
    /// no system grabber. A nil height opens at the large detent.
    func progressSubsheet(height: CGFloat?) -> some View {
        self
            .presentationDetents(height.map { [.height($0)] } ?? [.large])
            .presentationBackground(SYN.card)
            .presentationCornerRadius(24)
            .presentationDragIndicator(.hidden)
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
