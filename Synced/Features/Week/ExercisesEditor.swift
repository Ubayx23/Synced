import SwiftUI

/// Editable exercise on the Log session sheet. Numbers stay as text while
/// typing; `cleaned` turns drafts into saveable exercises.
struct ExerciseDraft: Identifiable, Equatable {
    let id = UUID()
    var name: String = ""
    var sets: [SetDraft] = [SetDraft()]

    init() {}

    init(_ exercise: LiftExercise) {
        name = exercise.name
        sets = exercise.sets.map(SetDraft.init)
        if sets.isEmpty { sets = [SetDraft()] }
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
    /// surrounding whitespace.
    var cleaned: [LiftExercise] {
        compactMap { draft in
            let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let sets = draft.sets.compactMap(\.value)
            guard !name.isEmpty, !sets.isEmpty else { return nil }
            return LiftExercise(name: name, sets: sets)
        }
    }
}

/// Optional exercises section for lift sessions: inline name, sets of
/// weight and reps, add and remove controls. No validation UI.
struct ExercisesEditor: View {
    @Binding var exercises: [ExerciseDraft]
    /// Past exercise names for the selected muscle groups, newest first.
    var suggestions: [String] = []

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

            ForEach($exercises) { $exercise in
                exerciseCard($exercise)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            addExerciseButton
        }
        .animation(.easeOut(duration: 0.2), value: exercises)
    }

    // MARK: - Exercise card

    private func exerciseCard(_ exercise: Binding<ExerciseDraft>) -> some View {
        let id = exercise.wrappedValue.id
        let setCount = exercise.wrappedValue.sets.count

        return VStack(alignment: .leading, spacing: Spacing.m) {
            // Offered while naming: when the name is empty or being edited.
            let chips = suggestionChips(for: exercise.wrappedValue)
            if !chips.isEmpty && (exercise.wrappedValue.name.isEmpty || focus == .name(id)) {
                suggestionRow(chips) { name in
                    exercise.wrappedValue.name = name
                    if let first = exercise.wrappedValue.sets.first { focus = .weight(first.id) }
                }
                .transition(.opacity)
            }

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

    // MARK: - Suggestions

    /// Drops names already used by another exercise in this session and the
    /// name this exercise already has.
    private func suggestionChips(for exercise: ExerciseDraft) -> [String] {
        let taken = Set(
            exercises
                .filter { $0.id != exercise.id }
                .map { $0.name.trimmingCharacters(in: .whitespaces).lowercased() }
        )
        let current = exercise.name.trimmingCharacters(in: .whitespaces).lowercased()
        return suggestions
            .filter { !taken.contains($0.lowercased()) && $0.lowercased() != current }
            .prefix(Self.maxSuggestions)
            .map { $0 }
    }

    private func suggestionRow(_ names: [String], onPick: @escaping (String) -> Void) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.s) {
                ForEach(names, id: \.self) { name in
                    Button { onPick(name) } label: {
                        Text(name)
                            .font(.synText(13, weight: .medium))
                            .foregroundStyle(SYN.textDim)
                            .padding(.horizontal, Spacing.m)
                            .frame(height: 30)
                            .background(Capsule().fill(SYN.surfaceHi))
                            .overlay(Capsule().stroke(SYN.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Fills the exercise name")
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Set row

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
                let draft = ExerciseDraft()
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
