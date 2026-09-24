import SwiftUI

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

    static let maxSuggestions = 6
    static let maxExercises = 8
    static let maxSets = 10

    private enum Field: Hashable {
        case name(UUID)
        case weight(UUID)
    }

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
        .animation(.easeOut(duration: 0.2), value: exercises)
        .animation(.easeOut(duration: 0.2), value: suggestions)
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
                .onSubmit {
                    if let first = exercise.wrappedValue.sets.first { focus = .weight(first.id) }
                }

                removeButton(label: "Remove exercise") {
                    exercises.removeAll { $0.id == id }
                }
            }

            // Only needed when the session covers more than one group.
            if selectedMuscles.count > 1 {
                musclePicker(for: exercise)
            }

            VStack(spacing: Spacing.s) {
                ForEach(Array(exercise.wrappedValue.sets.enumerated()), id: \.element.id) { index, set in
                    setRow(number: index + 1, set: binding(for: set.id, in: exercise)) {
                        exercise.wrappedValue.sets.removeAll { $0.id == set.id }
                    }
                }
            }

            HStack(spacing: Spacing.s) {
                Button {
                    let set = SetDraft(copying: exercise.wrappedValue.sets.last)
                    exercise.wrappedValue.sets.append(set)
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
                        .foregroundStyle(selected ? SessionType.lift.color : SYN.textFaint)
                        .padding(.horizontal, Spacing.s)
                        .frame(height: 26)
                        .background(Capsule().fill(selected ? SessionType.lift.color.opacity(0.12) : .clear))
                        .overlay(Capsule().stroke(selected ? SessionType.lift.color.opacity(0.6) : SYN.border, lineWidth: 1))
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
        let hasEmptyCard = exercises.contains { $0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        guard hasEmptyCard || exercises.count < Self.maxExercises else { return [] }
        let taken = Set(exercises.map { $0.name.trimmingCharacters(in: .whitespaces).lowercased() })
        return suggestions
            .filter { !taken.contains($0.id) }
            .prefix(Self.maxSuggestions)
            .map { $0 }
    }

    /// Fills the last unnamed card if there is one, otherwise adds a new
    /// exercise. Sets come from the last time it was logged unless the card
    /// already has numbers in it.
    private func addSuggested(_ suggestion: ExerciseSuggestion) {
        if let i = exercises.lastIndex(where: { $0.name.trimmingCharacters(in: .whitespaces).isEmpty }) {
            let filled = ExerciseDraft(suggestion)
            exercises[i].name = filled.name
            exercises[i].muscle = filled.muscle
            if exercises[i].hasNoSetValues { exercises[i].sets = filled.sets }
        } else if exercises.count < Self.maxExercises {
            exercises.append(ExerciseDraft(suggestion))
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

            numberField(text: set.weight, placeholder: "0", unit: "lbs", keyboard: .decimalPad)
                .focused($focus, equals: .weight(set.wrappedValue.id))

            Text("×")
                .font(.synText(13))
                .foregroundStyle(SYN.textFaint)

            numberField(text: set.reps, placeholder: "0", unit: "reps", keyboard: .numberPad)

            removeButton(label: "Remove set \(number)", action: onRemove)
        }
    }

    private func numberField(
        text: Binding<String>,
        placeholder: String,
        unit: String,
        keyboard: UIKeyboardType
    ) -> some View {
        HStack(spacing: Spacing.xs) {
            TextField("", text: text, prompt: Text(placeholder).foregroundColor(SYN.textFaint))
                .font(.synMono(15, weight: .medium))
                .foregroundStyle(SYN.text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
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
                exercises.append(draft)
                focus = .name(draft.id)
            } label: {
                Label("Add exercise", systemImage: "plus")
                    .font(.synText(15, weight: .medium))
                    .foregroundStyle(atLimit ? SYN.textFaint : SYN.textDim)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .strokeBorder(SYN.border, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
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
