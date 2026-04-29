import SwiftUI

/// Pill-tag input for foods. Typed entries commit on comma or return.
/// Chip-tap entries arrive pre-split (handled by the parent).
struct MealTagInput: View {
    @Binding var items: [String]

    @State private var currentInput: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(SYN.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(SYN.cyan, lineWidth: 1.5)
                )

            content
                .padding(12)
        }
        .frame(minHeight: 56)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
    }

    @ViewBuilder
    private var content: some View {
        if items.isEmpty && !isFocused && currentInput.isEmpty {
            Text("Add foods one at a time...")
                .font(.system(size: 15))
                .foregroundColor(SYN.textFaint)
                .padding(.vertical, 4)
                .padding(.horizontal, 4)
        } else {
            FlowLayout(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    PillView(text: item) {
                        withAnimation(.spring(response: 0.3)) {
                            items.removeAll { $0 == item }
                        }
                    }
                }

                TextField(
                    items.isEmpty ? "e.g. rice cakes" : "Add another...",
                    text: $currentInput
                )
                .focused($isFocused)
                .font(.system(size: 15))
                .foregroundColor(SYN.text)
                .tint(SYN.cyan)
                .frame(minWidth: 120)
                .frame(height: 32)
                .submitLabel(.done)
                .onSubmit { commitCurrentInput() }
                .onChange(of: currentInput) { _, newValue in
                    if newValue.contains(",") {
                        commitCurrentInput()
                    }
                }
            }
        }
    }

    private func commitCurrentInput() {
        let cleaned = currentInput.replacingOccurrences(of: ",", with: "")
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            currentInput = ""
            return
        }
        withAnimation(.spring(response: 0.25)) {
            items.append(trimmed)
        }
        currentInput = ""
    }
}

// MARK: - Pill

private struct PillView: View {
    let text: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SYN.text)

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
