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
    @Binding var mealType: String
    @Binding var mealTime: Date
    @Binding var liftTime: Date

    @FocusState private var inputFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowText(text: "Step 2 of 3")
                    .foregroundStyle(SYN.textFaint)

                Spacer().frame(height: 24)

                Text("Food and timing.")
                    .font(.synDisplay(28, weight: .bold))
                    .foregroundStyle(SYN.text)

                Spacer().frame(height: 8)

                Text("This is where your trends come from.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)

                Spacer().frame(height: 24)

                mealSection

                Spacer().frame(height: 24)

                divider

                Spacer().frame(height: 24)

                mealTimeSection

                Spacer().frame(height: 24)

                divider

                Spacer().frame(height: 24)

                liftTimeSection

                Spacer().frame(height: 16)

                gapLabel
                    .frame(maxWidth: .infinity)

                Color.clear.frame(height: 32)
            }
            .padding(.horizontal, Spacing.pageH)
        }
    }

    // MARK: - Meal section

    private var mealSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "What did you eat?")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 8)

            inputField

            Spacer().frame(height: 8)

            chipScroller
        }
    }

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
                text: $mealType,
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

    private var chipScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(recentMeals, id: \.self) { meal in
                    MealChip(
                        meal: meal,
                        isSelected: mealType == meal,
                        onTap: {
                            inputFocused = false
                            mealType = meal
                        }
                    )
                }
            }
            .padding(.horizontal, Spacing.pageH)
        }
        .padding(.horizontal, -Spacing.pageH)
    }

    // MARK: - Meal time

    private var mealTimeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "What time did you eat?")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 12)

            TimePickerInput(selectedTime: $mealTime)
        }
    }

    // MARK: - Lift time

    private var liftTimeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "What time are you lifting?")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 8)

            Text("We'll track which times you perform best.")
                .font(.synText(13))
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 12)

            TimePickerInput(selectedTime: $liftTime)
        }
    }

    // MARK: - Gap label

    @ViewBuilder
    private var gapLabel: some View {
        if liftTime <= mealTime {
            Text("Lift time must be after meal time")
                .font(.synText(13))
                .foregroundStyle(SYN.red)
        } else {
            let interval = Int(liftTime.timeIntervalSince(mealTime) / 60)
            let hours = interval / 60
            let mins = interval % 60

            VStack(spacing: 4) {
                Text(gapPhrase(hours: hours, mins: mins))
                    .font(.synText(13))
                    .foregroundStyle(SYN.textDim)

                Text(contextLabel(forMinutes: interval).text)
                    .font(.synText(13))
                    .foregroundStyle(contextLabel(forMinutes: interval).color)
            }
        }
    }

    private func gapPhrase(hours: Int, mins: Int) -> String {
        if hours > 0 && mins > 0 { return "That's \(hours) hr \(mins) min gap" }
        if hours > 0 { return "That's \(hours) hr gap" }
        return "That's \(mins) min gap"
    }

    private func contextLabel(forMinutes total: Int) -> (text: String, color: Color) {
        switch total {
        case ..<60:    return ("Still digesting, may affect your lift", SYN.amber)
        case 60..<90:  return ("Getting there",                          SYN.textDim)
        case 90..<180: return ("Sweet spot",                              SYN.cyan)
        default:       return ("Fully digested",                          SYN.green)
        }
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(SYN.border)
            .frame(height: 1)
            .padding(.horizontal, 24)
    }
}
