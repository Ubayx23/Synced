import SwiftUI

/// Pill-tag input for foods with optional inline carb capture.
///
/// Flow: type a name → comma or return commits the name → carb input appears →
/// type carbs (or Skip) → pill commits with optional `carbsG`. While a carb is
/// pending, the name input is hidden and chips are blocked (parent enforces).
struct MealTagInput: View {
    @Binding var items: [FoodItem]
    /// One-way reflection of internal pending state so the parent can disable
    /// chips and the Continue button while a pill is mid-capture.
    @Binding var isAddingCarb: Bool

    @State private var currentInput: String = ""
    @State private var carbInput: String = ""
    @State private var pendingItem: FoodItem? = nil

    @FocusState private var focusedField: FocusField?

    enum FocusField { case nameInput, carbInput }

    var body: some View {
        VStack(spacing: 8) {
            tagContainer

            if pendingItem != nil {
                carbRow
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onChange(of: pendingItem) { _, new in
            isAddingCarb = (new != nil)
        }
    }

    // MARK: - Container

    private var tagContainer: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(SYN.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(SYN.cyan, lineWidth: 1.5)
                )

            FlowLayout(spacing: 8) {
                ForEach(items) { item in
                    PillView(item: item) {
                        withAnimation(.spring(response: 0.3)) {
                            items.removeAll { $0.id == item.id }
                        }
                    }
                }

                if pendingItem == nil {
                    nameField
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .topLeading)
        .contentShape(Rectangle())
        .onTapGesture {
            if pendingItem == nil { focusedField = .nameInput }
        }
    }

    private var nameField: some View {
        TextField(placeholder, text: $currentInput)
            .focused($focusedField, equals: .nameInput)
            .font(.system(size: 15))
            .foregroundColor(SYN.text)
            .tint(SYN.cyan)
            .frame(minWidth: 120)
            .frame(height: 32)
            .submitLabel(.next)
            .onSubmit { commitName() }
            .onChange(of: currentInput) { _, newValue in
                if newValue.contains(",") { commitName() }
            }
            .transaction { $0.animation = nil }
    }

    private var placeholder: String {
        items.isEmpty ? "Add foods one at a time..." : "Add another..."
    }

    private var addEnabled: Bool {
        !carbInput.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Carb capture row

    private var carbRow: some View {
        HStack(spacing: 8) {
            if let pending = pendingItem {
                Text("Carbs in \(pending.name):")
                    .font(.system(size: 13))
                    .foregroundColor(SYN.textDim)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            TextField("0", text: $carbInput)
                .focused($focusedField, equals: .carbInput)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 15, design: .monospaced))
                .foregroundColor(SYN.text)
                .frame(width: 60, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SYN.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(SYN.cyan, lineWidth: 1)
                )

            Text("g")
                .font(.system(size: 13))
                .foregroundColor(SYN.textDim)

            Spacer()

            Button(action: { commitCarb(skip: true) }) {
                Text("Skip")
                    .font(.synText(13, weight: .medium))
                    .foregroundStyle(SYN.textDim)
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: { commitCarb(skip: false) }) {
                Text("Add")
                    .font(.synText(13, weight: .semibold))
                    .foregroundStyle(addEnabled ? Color.black : SYN.textFaint)
                    .padding(.horizontal, 14)
                    .frame(height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(addEnabled ? SYN.cyan : SYN.surfaceHi)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!addEnabled)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SYN.surfaceHi)
        )
    }

    // MARK: - Commit logic

    private func commitName() {
        let trimmed = currentInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")
        guard trimmed.count >= 2 else {
            currentInput = ""
            return
        }
        withAnimation(.spring(response: 0.25)) {
            pendingItem = FoodItem(name: trimmed)
        }
        currentInput = ""
        carbInput = ""
        DispatchQueue.main.async { focusedField = .carbInput }
    }

    private func commitCarb(skip: Bool) {
        guard var item = pendingItem else { return }
        if !skip {
            let trimmed = carbInput.trimmingCharacters(in: .whitespaces)
            if let carbs = Int(trimmed), carbs >= 0 {
                item.carbsG = carbs
            }
        }
        withAnimation(.spring(response: 0.25)) {
            items.append(item)
            pendingItem = nil
        }
        carbInput = ""
        DispatchQueue.main.async { focusedField = .nameInput }
    }
}

// MARK: - Pill

private struct PillView: View {
    let item: FoodItem
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(item.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(SYN.text)

            if let carbs = item.carbsG {
                Text("· \(carbs)g")
                    .font(.system(size: 13))
                    .foregroundColor(SYN.cyan)
            }

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(SYN.textDim)
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(SYN.surfaceHi)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SYN.cyan, lineWidth: 1)
        )
        .shadow(color: SYN.cyan.opacity(0.15), radius: 6)
    }
}

// MARK: - Wrapping flow layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += lineHeight + spacing
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: maxWidth.isFinite ? maxWidth : x, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                y += lineHeight + spacing
                x = bounds.minX
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
