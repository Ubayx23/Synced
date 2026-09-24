import SwiftUI

/// Single adaptive form for logging a session. With no `session` it logs a
/// fresh session for today; with a planned or logged session it pre-fills
/// from that row and saves back to it.
struct LogSessionSheet: View {
    let session: Session?
    let store: WeekStore

    @Environment(\.dismiss) private var dismiss
    @State private var type: SessionType?
    @State private var grades: [Int]
    @State private var muscles: Set<MuscleGroup>
    @State private var rating: Int?
    @State private var notes: String
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var confirmingDelete = false
    @State private var errorMessage: String?
    @FocusState private var notesFocused: Bool

    init(session: Session?, store: WeekStore) {
        self.session = session
        self.store = store
        _type = State(initialValue: session?.type)
        _grades = State(initialValue: session?.grades ?? [])
        _muscles = State(initialValue: Set(session?.muscles ?? []))
        _rating = State(initialValue: session?.rating)
        _notes = State(initialValue: session?.notes ?? "")
    }

    private var canSave: Bool {
        switch type {
        case .climb: return !grades.isEmpty
        case .lift:  return !muscles.isEmpty
        case .rest:  return true
        case nil:    return false
        }
    }

    private var title: String {
        guard let session else { return "Log today's session" }
        let verb = session.isPlanned ? "Log" : "Edit"
        let day = session.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        return "\(verb) \((type ?? session.type).title) for \(day)"
    }

    private var notesPlaceholder: String {
        switch type {
        case .climb: return "Sent V4 first try, forearms tanked on the project"
        case .lift:  return "Bench PR, tri fried"
        case .rest:  return "Stretched, walked, slept nine hours"
        case nil:    return "How did it go?"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, Spacing.pageH)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.md)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    section("Type") { typePicker }

                    if type == .climb {
                        section("Sends", trailing: sendsSummary) {
                            VStack(alignment: .leading, spacing: Spacing.m) {
                                sendsRow
                                gradePicker
                            }
                        }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    if type == .lift {
                        section("Focus", trailing: "Pick one or more") { musclePicker }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    section("Rating", optional: true) { ratingPicker }
                    section("Notes", optional: true) { notesField }

                    saveArea
                }
                .padding(.horizontal, Spacing.pageH)
                .padding(.top, Spacing.s)
                .padding(.bottom, Spacing.lg)
                .animation(.easeOut(duration: 0.22), value: type)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(SYN.bg)
        .presentationCornerRadius(Radius.card * 2)
        .interactiveDismissDisabled(isSaving || isDeleting)
        .confirmationDialog("Delete this session?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteSession() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Text(title)
                .font(.synDisplay(22, weight: .bold))
                .foregroundStyle(SYN.text)
                .kerning(-0.4)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.opacity)

            Spacer(minLength: 0)

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SYN.textDim)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(SYN.surface))
                    .overlay(Circle().stroke(SYN.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }

    // MARK: - Sections

    private func section<Content: View>(
        _ label: String,
        optional: Bool = false,
        trailing: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                EyebrowText(text: label)
                    .foregroundStyle(SYN.textFaint)
                Spacer()
                if let hint = trailing ?? (optional ? "Optional" : nil) {
                    Text(hint)
                        .font(.synText(12))
                        .foregroundStyle(SYN.textFaint)
                        .contentTransition(.numericText())
                }
            }
            content()
        }
    }

    private var typePicker: some View {
        HStack(spacing: Spacing.m) {
            ForEach(SessionType.allCases) { option in
                let selected = type == option
                Button {
                    type = option
                } label: {
                    VStack(spacing: Spacing.s) {
                        Image(systemName: option.symbol)
                            .font(.system(size: 20, weight: .semibold))
                            .frame(height: 24)
                        Text(option.title)
                            .font(.synText(15, weight: .semibold))
                    }
                    .foregroundStyle(selected ? option.color : SYN.textDim)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .fill(selected ? option.color.opacity(0.1) : SYN.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .stroke(selected ? option.color.opacity(0.8) : SYN.border, lineWidth: 1)
                    )
                    .shadow(color: selected ? option.color.opacity(0.3) : .clear, radius: 14)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .animation(.easeOut(duration: 0.18), value: type)
    }

    /// "3 sends, top V4" once anything is logged.
    private var sendsSummary: String? {
        guard let top = grades.max() else { return nil }
        return "\(grades.count) \(grades.count == 1 ? "send" : "sends"), top V\(top)"
    }

    /// One chip per grade with its count. Tapping a chip removes one send.
    private var sendsRow: some View {
        let counts = Dictionary(grouping: grades, by: { $0 }).mapValues(\.count)
        return Group {
            if counts.isEmpty {
                Text("Tap a grade below to add a send.")
                    .font(.synText(14))
                    .foregroundStyle(SYN.textFaint)
                    .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: Spacing.s) {
                        ForEach(counts.keys.sorted(), id: \.self) { value in
                            SendChip(grade: value, count: counts[value] ?? 0) {
                                removeSend(value)
                            }
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal, -Spacing.pageH)
                .contentMargins(.horizontal, Spacing.pageH, for: .scrollContent)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: grades)
    }

    /// Each tap adds one send at that grade. Grades already sent stay lit.
    private var gradePicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: Spacing.s) {
                    ForEach(0...17, id: \.self) { value in
                        OptionPill(
                            title: "V\(value)",
                            color: SessionType.climb.color,
                            selected: grades.contains(value),
                            mono: true
                        ) {
                            grades.append(value)
                            grades.sort()
                        }
                        .id(value)
                        .accessibilityLabel("Add a V\(value) send")
                    }
                }
                .padding(.vertical, Spacing.xs)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                if let top = grades.max() { proxy.scrollTo(top, anchor: .center) }
            }
        }
        .padding(.horizontal, -Spacing.pageH)
        .contentMargins(.horizontal, Spacing.pageH, for: .scrollContent)
    }

    private func removeSend(_ value: Int) {
        if let index = grades.firstIndex(of: value) {
            grades.remove(at: index)
        }
    }

    /// Toggle per pill; any number can be on.
    private var musclePicker: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.s), count: 3),
            spacing: Spacing.s
        ) {
            ForEach(MuscleGroup.allCases) { option in
                OptionPill(
                    title: option.title,
                    color: SessionType.lift.color,
                    selected: muscles.contains(option),
                    fillsWidth: true
                ) {
                    if muscles.contains(option) {
                        muscles.remove(option)
                    } else {
                        muscles.insert(option)
                    }
                }
            }
        }
    }

    private var ratingPicker: some View {
        HStack(spacing: 0) {
            ForEach(1...5, id: \.self) { value in
                let selected = rating == value
                let color = Session.ratingColor(value)
                Button {
                    rating = selected ? nil : value
                } label: {
                    Text("\(value)")
                        .font(.synMono(17, weight: .semibold))
                        .foregroundStyle(selected ? SYN.bg : SYN.textDim)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(selected ? color : SYN.surface))
                        .overlay(Circle().stroke(selected ? color : SYN.border, lineWidth: 1))
                        .shadow(color: selected ? color.opacity(0.45) : .clear, radius: 12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rating \(value) of 5")
                .accessibilityAddTraits(selected ? .isSelected : [])

                if value < 5 { Spacer(minLength: 0) }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: rating)
    }

    private var notesField: some View {
        TextField(
            "",
            text: $notes,
            prompt: Text(notesPlaceholder).foregroundColor(SYN.textFaint),
            axis: .vertical
        )
        .lineLimit(2...3)
        .font(.synText(16))
        .foregroundStyle(SYN.text)
        .focused($notesFocused)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                .fill(SYN.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                .stroke(notesFocused ? SYN.cyan : SYN.border, lineWidth: 1.5)
        )
        .shadow(color: notesFocused ? SYN.cyan.opacity(0.45) : .clear, radius: 12)
        .animation(.easeOut(duration: 0.2), value: notesFocused)
    }

    // MARK: - Save

    /// Sits directly under the form so the sheet reads as one composition.
    private var saveArea: some View {
        VStack(spacing: Spacing.m) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.synText(13))
                    .foregroundStyle(SYN.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            PrimaryButton(title: isSaving ? "Saving" : "Save session", disabled: !canSave || isSaving || isDeleting) {
                save()
            }

            // Only existing sessions (planned or logged) can be deleted; a
            // fresh log has no row yet. Extra space keeps it away from Save.
            if session != nil {
                Button {
                    confirmingDelete = true
                } label: {
                    HStack(spacing: Spacing.s) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                        Text(isDeleting ? "Deleting" : "Delete session")
                            .font(.synText(15, weight: .medium))
                    }
                    .foregroundStyle(SYN.red)
                    .padding(.horizontal, Spacing.lg)
                    .frame(height: 44)
                    .background(Capsule().fill(SYN.red.opacity(0.06)))
                    .overlay(Capsule().stroke(SYN.red.opacity(0.45), lineWidth: 1))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isSaving || isDeleting)
                .padding(.top, Spacing.lg)
            }
        }
    }

    private func deleteSession() {
        guard let session, !isDeleting else { return }
        isDeleting = true
        errorMessage = nil
        Task {
            do {
                try await store.delete(session)
                dismiss()
            } catch {
                isDeleting = false
                errorMessage = "Couldn't delete. Try again."
            }
        }
    }

    private func save() {
        guard let type, canSave, !isSaving, !isDeleting else { return }
        isSaving = true
        errorMessage = nil
        let log = SessionLog(
            id: session?.id,
            type: type,
            date: session?.date ?? Date(),
            grades: grades,
            muscles: muscles,
            rating: rating,
            notes: notes
        )
        Task {
            do {
                try await store.log(log)
                dismiss()
            } catch {
                isSaving = false
                errorMessage = "Couldn't save that session. \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Send chip

/// "V2 ×2" with a minus badge; tapping it removes one send at that grade.
private struct SendChip: View {
    let grade: Int
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("V\(grade)")
                    .font(.synMono(15, weight: .semibold))
                Text("×\(count)")
                    .font(.synMono(13, weight: .medium))
                    .opacity(0.7)
                    .contentTransition(.numericText())
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .opacity(0.8)
            }
            .foregroundStyle(SYN.bg)
            .padding(.leading, Spacing.m)
            .padding(.trailing, Spacing.s)
            .frame(height: 36)
            .background(Capsule().fill(SessionType.climb.color))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("V\(grade), \(count) \(count == 1 ? "send" : "sends")")
        .accessibilityHint("Removes one send")
    }
}

// MARK: - Option pill

/// Single-select pill used for grades and muscle groups.
private struct OptionPill: View {
    let title: String
    let color: Color
    let selected: Bool
    var mono: Bool = false
    var fillsWidth: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(mono ? .synMono(15, weight: .semibold) : .synText(15, weight: .semibold))
                .foregroundStyle(selected ? color : SYN.textDim)
                .padding(.horizontal, Spacing.md)
                .frame(maxWidth: fillsWidth ? .infinity : nil)
                .frame(height: 44)
                .background(Capsule().fill(selected ? color.opacity(0.12) : SYN.surface))
                .overlay(Capsule().stroke(selected ? color.opacity(0.8) : SYN.border, lineWidth: 1))
                .shadow(color: selected ? color.opacity(0.3) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .animation(.easeOut(duration: 0.18), value: selected)
    }
}
