import SwiftUI

private let recentMeals: [String] = [
    "Chicken, rice, broccoli",
    "Rice cakes, honey, salt",
    "Eggs, avocado toast",
    "Protein shake, banana",
    "Oats, peanut butter",
    "Salmon, sweet potato",
]

struct FoodStep: View {
    @Binding var mealItems: [FoodItem]

    @State private var isAddingCarb: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "Step 3 of 4")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 24)

            Text("What did you eat?")
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)

            Spacer().frame(height: 8)

            Text("Be specific. This builds your trends.")
                .font(.synText(15))
                .foregroundStyle(SYN.textDim)

            Spacer().frame(height: 40)

            MealTagInput(items: $mealItems, isAddingCarb: $isAddingCarb)

            Spacer().frame(height: 16)

            chipScroller
                .opacity(isAddingCarb ? 0.4 : 1)
                .allowsHitTesting(!isAddingCarb)

            Spacer().frame(height: 16)

            Text("Each food tracked with carb count for better trends.")
                .font(.synText(12))
                .foregroundStyle(SYN.textFaint)

            Spacer()
        }
        .padding(.horizontal, Spacing.pageH)
    }

    private var chipScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(recentMeals, id: \.self) { meal in
                    MealChip(
                        meal: meal,
                        isSelected: false,
                        onTap: { handleChipTap(meal) }
                    )
                }
            }
            .padding(.horizontal, Spacing.pageH)
        }
        .padding(.horizontal, -Spacing.pageH)
    }

    private func handleChipTap(_ meal: String) {
        guard !isAddingCarb else { return }
        let parts = meal
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let existing = Set(mealItems.map { $0.name.lowercased() })
        var toAdd: [FoodItem] = []
        for part in parts where !existing.contains(part.lowercased()) {
            if !toAdd.contains(where: { $0.name.lowercased() == part.lowercased() }) {
                toAdd.append(FoodItem(name: part))
            }
        }
        guard !toAdd.isEmpty else { return }
        withAnimation(.spring(response: 0.25)) {
            mealItems.append(contentsOf: toAdd)
        }
    }
}
