import SwiftUI
import UIKit

/// UITextField wrapper so tapping a numeric field always lands the cursor
/// at the end of the current value, never mid-string and never select-all.
/// SwiftUI's TextField has no API for cursor position.
private struct CursorEndField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let isFocused: Binding<Bool>

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.keyboardType = keyboardType
        field.textAlignment = .right
        field.font = UIFont(name: "GeistMono-Medium", size: 15)
        field.textColor = UIColor(SYN.text)
        field.tintColor = UIColor(SYN.cyan)
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(SYN.textFaint)]
        )
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged), for: .editingChanged)
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if isFocused.wrappedValue, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused.wrappedValue, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: isFocused)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        let text: Binding<String>
        let isFocused: Binding<Bool>

        init(text: Binding<String>, isFocused: Binding<Bool>) {
            self.text = text
            self.isFocused = isFocused
        }

        @objc func editingChanged(_ field: UITextField) {
            text.wrappedValue = field.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            isFocused.wrappedValue = true
            // Cursor at the end on focus. No select-all.
            let end = textField.endOfDocument
            textField.selectedTextRange = textField.textRange(from: end, to: end)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            isFocused.wrappedValue = false
        }
    }
}

/// Editable exercise on the Log session sheet. Numbers stay as text while
/// typing; `cleaned(for:)` turns drafts into saveable exercises.
struct ExerciseDraft: Identifiable, Equatable {
    let id = UUID()
    var name: String = ""
    var sets: [SetDraft] = [SetDraft()]
    /// The muscle group this exercise counts for. Resolved against the
    /// session's selection by `effectiveMuscle(in:)`.
    var muscle: MuscleGroup?

    init(muscle: MuscleGroup? = nil) {
        self.muscle = muscle
    }

    init(_ exercise: LiftExercise) {
        name = exercise.name
        muscle = exercise.muscleGroup.flatMap(MuscleGroup.init(rawValue:))
        sets = exercise.sets.map(SetDraft.init)
        if sets.isEmpty { sets = [SetDraft()] }
    }

    /// A suggestion pre-fills the name, group, and last time's sets.
    init(_ suggestion: ExerciseSuggestion) {
        name = suggestion.name
        muscle = suggestion.muscle
        sets = suggestion.sets.map(SetDraft.init)
        if sets.isEmpty { sets = [SetDraft()] }
    }

    /// Own group if it is still selected, otherwise the first selected group.
    func effectiveMuscle(in selected: [MuscleGroup]) -> MuscleGroup? {
        if let muscle, selected.contains(muscle) { return muscle }
        return selected.first
    }

    var hasNoSetValues: Bool {
        sets.allSatisfy { $0.weight.isEmpty && $0.reps.isEmpty }
    }
}

struct SetDraft: Identifiable, Equatable {
    let id = UUID()
    var weight: String = ""
    var reps: String = ""

    init() {}

    /// Starts from the previous set's values; most sets repeat or nudge them.
    init(copying set: SetDraft?) {
        weight = set?.weight ?? ""
        reps = set?.reps ?? ""
    }

    init(_ set: LiftSet) {
        weight = set.weightLbs.rounded() == set.weightLbs
            ? String(Int(set.weightLbs))
            : String(set.weightLbs)
        reps = String(set.reps)
    }

    /// nil when weight or reps is empty or zero.
    var value: LiftSet? {
        let normalized = weight.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard
            let w = Double(normalized), w > 0,
            let r = Int(reps.trimmingCharacters(in: .whitespaces)), r > 0
        else { return nil }
        return LiftSet(weightLbs: w, reps: r)
    }
}

extension Array where Element == ExerciseDraft {
    /// Silent cleanup on save: drops unnamed exercises, invalid sets, and
    /// exercises left with no sets. Names are kept as typed apart from
    /// surrounding whitespace. Each exercise is tagged with one muscle group.
    func cleaned(for selected: [MuscleGroup]) -> [LiftExercise] {
        compactMap { draft in
            let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let sets = draft.sets.compactMap(\.value)
            guard !name.isEmpty, !sets.isEmpty else { return nil }
            return LiftExercise(
                name: name,
                sets: sets,
                muscleGroup: draft.effectiveMuscle(in: selected)?.rawValue
            )
        }
    }
}

/// Optional exercises section for lift sessions: suggestion chips from past
/// sessions, inline name, muscle group, sets of weight and reps, and add and
/// remove controls. No validation UI.
struct ExercisesEditor: View {
    @Binding var exercises: [ExerciseDraft]
    /// Session's selected muscle groups, in grid order.
    var selectedMuscles: [MuscleGroup] = []
    /// Past exercises for the selected muscle groups, newest first.
    var suggestions: [ExerciseSuggestion] = []
    /// Removes a chip from future suggestions.
    var onHideSuggestion: (ExerciseSuggestion) -> Void = { _ in }
    /// Scrolls the enclosing sheet so a newly focused field stays visible
    /// above the keyboard. Nil when the editor isn't inside a ScrollViewReader.
    var scrollProxy: ScrollViewProxy?

    static let maxSuggestions = 6
    static let maxExercises = 8
    static let maxSets = 10

    private enum Field: Hashable {
        case name(UUID)
        case weight(UUID)
        case reps(UUID)
    }

    /// Structural changes only. Animating on every keystroke re-lays out the
    /// text fields mid-edit and throws the cursor to the end.
    private let structural = Animation.easeOut(duration: 0.2)

    @FocusState private var focus: Field?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Track weight and reps to see progression on the Progress tab.")
                .font(.synText(13))
                .foregroundStyle(SYN.textFaint)
                .fixedSize(horizontal: false, vertical: true)

            if !availableSuggestions.isEmpty {
                suggestionRow
                    .transition(.opacity)
            }

            // Bound by id, not index: a card still animating out after its
            // exercise is removed must not read past the end of the array.
            ForEach(exercises) { exercise in
                exerciseCard(id: exercise.id, exercise: binding(forExercise: exercise.id))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            addExerciseButton
        }
        .animation(structural, value: suggestions)
        .animation(structural, value: exercises.map(\.id))
        .onChange(of: focus) { old, new in
            // Clean up whatever was typed once a number field loses focus.
            if let old { sanitize(old) }
            // Keep the newly focused field visible above the keyboard.
            if let new { scrollProxy?.scrollTo(new, anchor: .center) }
        }
    }

    // MARK: - Exercise card

    private func exerciseCard(id: UUID, exercise: Binding<ExerciseDraft>) -> some View {
        let setCount = exercise.wrappedValue.sets.count

        return VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(spacing: Spacing.s) {
                TextField(
                    "",
                    text: exercise.name,
                    prompt: Text("Exercise, e.g. Bench press").foregroundColor(SYN.textFaint)
                )
                .font(.synText(16, weight: .semibold))
                .foregroundStyle(SYN.text)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.next)
                .focused($focus, equals: .name(id))
                .id(Field.name(id))
                .onSubmit {
                    if let first = exercise.wrappedValue.sets.first { focus = .weight(first.id) }
                }

                removeButton(label: "Remove exercise") {
                    withAnimation(structural) { exercises.removeAll { $0.id == id } }
                }
            }

            // Only needed when the session covers more than one group.
            if selectedMuscles.count > 1 {
                musclePicker(for: exercise)
            }

            VStack(spacing: Spacing.s) {
                ForEach(Array(exercise.wrappedValue.sets.enumerated()), id: \.element.id) { index, set in
                    setRow(number: index + 1, set: binding(for: set.id, in: exercise)) {
                        withAnimation(structural) {
                            exercise.wrappedValue.sets.removeAll { $0.id == set.id }
                        }
                    }
                }
            }

            HStack(spacing: Spacing.s) {
                Button {
                    let set = SetDraft(copying: exercise.wrappedValue.sets.last)
                    withAnimation(structural) { exercise.wrappedValue.sets.append(set) }
                    focus = .weight(set.id)
                } label: {
                    Label("Add set", systemImage: "plus")
                        .font(.synText(13, weight: .semibold))
                        .foregroundStyle(setCount >= Self.maxSets ? SYN.textFaint : SYN.textDim)
                        .frame(height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(setCount >= Self.maxSets)

                if setCount >= Self.maxSets {
                    Text("Max \(Self.maxSets) sets")
                        .font(.synText(12))
                        .foregroundStyle(SYN.textFaint)
                }
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(SYN.surface.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(SYN.border, lineWidth: 1)
        )
    }

    /// Which selected group this exercise counts for, so it is suggested
    /// under that group next time.
    private func musclePicker(for exercise: Binding<ExerciseDraft>) -> some View {
        let current = exercise.wrappedValue.effectiveMuscle(in: selectedMuscles)
        return HStack(spacing: Spacing.xs) {
            Text("For")
                .font(.synText(12))
                .foregroundStyle(SYN.textFaint)
            ForEach(selectedMuscles) { muscle in
                let selected = current == muscle
                Button { exercise.wrappedValue.muscle = muscle } label: {
                    Text(muscle.title)
                        .font(.synText(12, weight: .semibold))
                        // Neutral selection, matching the focus chips.
                        .foregroundStyle(selected ? SYN.text : SYN.textFaint)
                        .padding(.horizontal, Spacing.s)
                        .frame(height: 26)
                        .background(Capsule().fill(selected ? SYN.surfaceHi : .clear))
                        .overlay(Capsule().stroke(selected ? SYN.text.opacity(0.9) : SYN.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Counts for \(muscle.title)")
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    // MARK: - Suggestions

    /// Past exercises for the selected muscle groups, minus names already in
    /// this session. Hidden when there is no room to add another exercise.
    private var availableSuggestions: [ExerciseSuggestion] {
        let hasEmptyCard = exercises.contains { $0.name.exerciseKey.isEmpty }
        guard hasEmptyCard || exercises.count < Self.maxExercises else { return [] }
        let taken = Set(exercises.map(\.name.exerciseKey))
        return suggestions
            .filter { !taken.contains($0.id) }
            .prefix(Self.maxSuggestions)
            .map { $0 }
    }

    /// Fills the last unnamed card if there is one, otherwise adds a new
    /// exercise. Sets come from the last time it was logged unless the card
    /// already has numbers in it.
    private func addSuggested(_ suggestion: ExerciseSuggestion) {
        if let i = exercises.lastIndex(where: { $0.name.exerciseKey.isEmpty }) {
            let filled = ExerciseDraft(suggestion)
            exercises[i].name = filled.name
            exercises[i].muscle = filled.muscle
            if exercises[i].hasNoSetValues { exercises[i].sets = filled.sets }
        } else if exercises.count < Self.maxExercises {
            withAnimation(structural) { exercises.append(ExerciseDraft(suggestion)) }
        }
        focus = nil
    }

    private var suggestionRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.s) {
                ForEach(availableSuggestions) { suggestion in
                    HStack(spacing: 0) {
                        Button { addSuggested(suggestion) } label: {
                            Text(suggestion.name)
                                .font(.synText(13, weight: .medium))
                                .foregroundStyle(SYN.textDim)
                                .padding(.leading, Spacing.m)
                                .padding(.trailing, Spacing.xs)
                                .frame(height: 32)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Adds this exercise with last time's sets")

                        Button { onHideSuggestion(suggestion) } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(SYN.textFaint)
                                .frame(width: 28, height: 32)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(suggestion.name) from suggestions")
                    }
                    .background(Capsule().fill(SYN.surfaceHi))
                    .overlay(Capsule().stroke(SYN.border, lineWidth: 1))
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Number cleanup

    /// Silently drops anything that is not a digit: weight keeps one decimal
    /// point (a comma counts as one), reps keep digits only. Runs when a
    /// field loses focus, never mid-typing, so the cursor is left alone.
    private func sanitize(_ field: Field) {
        let setID: UUID
        let isWeight: Bool
        switch field {
        case .weight(let id): setID = id; isWeight = true
        case .reps(let id):   setID = id; isWeight = false
        case .name:           return
        }
        guard
            let e = exercises.firstIndex(where: { $0.sets.contains { $0.id == setID } }),
            let s = exercises[e].sets.firstIndex(where: { $0.id == setID })
        else { return }

        let raw = isWeight ? exercises[e].sets[s].weight : exercises[e].sets[s].reps
        var seenPoint = false
        let cleaned = String(raw.compactMap { char -> Character? in
            if char.isASCII && char.isNumber { return char }
            if isWeight && (char == "." || char == ","), !seenPoint {
                seenPoint = true
                return "."
            }
            return nil
        })
        guard cleaned != raw else { return }
        if isWeight {
            exercises[e].sets[s].weight = cleaned
        } else {
            exercises[e].sets[s].reps = cleaned
        }
    }

    // MARK: - Bindings

    /// Safe for views that outlive their exercise: reads fall back to an
    /// empty draft and writes to a missing id are dropped.
    private func binding(forExercise id: UUID) -> Binding<ExerciseDraft> {
        Binding(
            get: { exercises.first { $0.id == id } ?? ExerciseDraft() },
            set: { newValue in
                if let i = exercises.firstIndex(where: { $0.id == id }) {
                    exercises[i] = newValue
                }
            }
        )
    }

    /// Looks the set up by id so edits land on the right row even after
    /// another set is removed.
    private func binding(for setID: UUID, in exercise: Binding<ExerciseDraft>) -> Binding<SetDraft> {
        Binding(
            get: { exercise.wrappedValue.sets.first { $0.id == setID } ?? SetDraft() },
            set: { newValue in
                if let i = exercise.wrappedValue.sets.firstIndex(where: { $0.id == setID }) {
                    exercise.wrappedValue.sets[i] = newValue
                }
            }
        )
    }

    // MARK: - Set row

    private func setRow(number: Int, set: Binding<SetDraft>, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: Spacing.s) {
            Text("\(number)")
                .font(.synMono(13, weight: .medium))
                .foregroundStyle(SYN.textFaint)
                .frame(width: 20, alignment: .leading)

            numberField(text: set.weight, placeholder: "0", unit: "lbs", keyboard: .decimalPad, id: .weight(set.wrappedValue.id))

            Text("×")
                .font(.synText(13))
                .foregroundStyle(SYN.textFaint)

            // Reps are whole numbers, so no decimal key.
            numberField(text: set.reps, placeholder: "0", unit: "reps", keyboard: .numberPad, id: .reps(set.wrappedValue.id))

            removeButton(label: "Remove set \(number)", action: onRemove)
        }
    }

    private func numberField(
        text: Binding<String>,
        placeholder: String,
        unit: String,
        keyboard: UIKeyboardType,
        id: Field
    ) -> some View {
        HStack(spacing: Spacing.xs) {
            CursorEndField(
                text: text,
                placeholder: placeholder,
                keyboardType: keyboard,
                isFocused: Binding(
                    get: { focus == id },
                    set: { newValue in
                        if newValue {
                            focus = id
                        } else if focus == id {
                            focus = nil
                        }
                    }
                )
            )
            .frame(maxWidth: .infinity)
            Text(unit)
                .font(.synText(12))
                .foregroundStyle(SYN.textFaint)
        }
        .padding(.horizontal, Spacing.m)
        .frame(height: 40)
        .background(
            RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                .fill(SYN.bg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                .stroke(SYN.border, lineWidth: 1)
        )
        .id(id)
    }

    private func removeButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(SYN.textFaint)
                .frame(width: 28, height: 28)
                .background(Circle().fill(SYN.surfaceHi))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Add exercise

    private var addExerciseButton: some View {
        let atLimit = exercises.count >= Self.maxExercises
        return VStack(spacing: Spacing.xs) {
            Button {
                // Starts with one empty set so the numbers have somewhere to go.
                let draft = ExerciseDraft(muscle: selectedMuscles.first)
                withAnimation(structural) { exercises.append(draft) }
                focus = .name(draft.id)
            } label: {
                // SecondaryButton pattern in the brand accent.
                Label("Add exercise", systemImage: "plus")
                    .font(.synText(15, weight: .medium))
                    .foregroundStyle(atLimit ? SYN.textFaint : SYN.cyan)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                            .strokeBorder(atLimit ? SYN.border : SYN.cyan, lineWidth: 1)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(atLimit)

            if atLimit {
                Text("Max \(Self.maxExercises) exercises")
                    .font(.synText(12))
                    .foregroundStyle(SYN.textFaint)
            }
        }
    }
}
