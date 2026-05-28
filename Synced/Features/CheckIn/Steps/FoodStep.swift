import SwiftUI

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

            Text("Each food tracked with carb count for better trends.")
                .font(.synText(12))
                .foregroundStyle(SYN.textFaint)

            Spacer()
        }
        .padding(.horizontal, Spacing.pageH)
    }
}
