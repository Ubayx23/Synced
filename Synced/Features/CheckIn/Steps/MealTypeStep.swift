import SwiftUI

private let recentMeals: [String] = [
    "Chicken, rice, broccoli",
    "Rice cakes, honey, salt",
    "Eggs, avocado toast",
    "Protein shake, banana",
    "Oats, peanut butter",
    "Salmon, sweet potato",
]

struct MealTypeStep: View {
    @Binding var value: String

    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "Step 3 of 5")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 24)

            Text("What did you eat?")
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)

            Spacer().frame(height: 8)

            Text("Be specific. This builds your trends.")
                .font(.synText(15))
                .foregroundStyle(SYN.textDim)

            Spacer().frame(height: 24)

            inputField

            Spacer().frame(height: 6)

            charCountRow

            Spacer().frame(height: 24)

            EyebrowText(text: "Recent")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 12)

            chipScroller

            Spacer().frame(height: 16)

            Text("Synced remembers your meals to spot patterns faster.")
                .font(.synText(12))
                .foregroundStyle(SYN.textFaint)

            Spacer()
        }
        .padding(.horizontal, Spacing.pageH)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                inputFocused = true
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: value)
    }

    // MARK: - Input

    private var inputField: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(SYN.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(SYN.cyan, lineWidth: 1.5)
                )

            TextField(
                "",
                text: $value,
                prompt: Text("e.g. chicken rice broccoli")
                    .foregroundStyle(SYN.textFaint),
                axis: .vertical
            )
            .lineLimit(1...3)
            .focused($inputFocused)
            .font(.synText(16))
            .foregroundStyle(SYN.text)
            .tint(SYN.cyan)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .transaction { $0.animation = nil }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var charCountRow: some View {
        HStack {
            Spacer()
            if value.count > 20 {
                Text("\(value.count) chars")
                    .font(.synText(11))
                    .foregroundStyle(SYN.textFaint)
            }
        }
        .frame(height: 14)
    }

    // MARK: - Chips

    private var chipScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(recentMeals, id: \.self) { meal in
                    MealChip(
                        meal: meal,
                        isSelected: value == meal,
                        onTap: { handleChipTap(meal) }
                    )
                }
            }
            .padding(.horizontal, Spacing.pageH)
        }
        .padding(.horizontal, -Spacing.pageH)
    }

    private func handleChipTap(_ meal: String) {
        inputFocused = false
        value = meal
    }
}
