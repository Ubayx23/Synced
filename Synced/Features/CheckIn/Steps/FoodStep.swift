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
    @Binding var mealItems: [String]
    @Binding var mealTime: Date
    @Binding var liftTime: Date

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowText(text: "Step 2 of 2")
                    .foregroundStyle(SYN.textFaint)

                Spacer().frame(height: 24)

                Text("Food and timing.")
                    .font(.synDisplay(28, weight: .bold))
                    .foregroundStyle(SYN.text)

                Spacer().frame(height: 8)

                Text("This is where your trends come from.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)

                Spacer().frame(height: 32)

                mealSection

                Spacer().frame(height: 32)

                divider

                Spacer().frame(height: 32)

                mealTimeSection

                Spacer().frame(height: 24)

                divider

                Spacer().frame(height: 24)

                liftTimeSection

                Spacer().frame(height: 20)

                gapBlock
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

            MealTagInput(items: $mealItems)

            Spacer().frame(height: 12)

            chipScroller

            Spacer().frame(height: 8)

            Text("Each food tracked separately for better trends.")
                .font(.synText(12))
                .foregroundStyle(SYN.textFaint)
        }
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
        let parts = meal
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let existing = Set(mealItems.map { $0.lowercased() })
        var toAdd: [String] = []
        for part in parts where !existing.contains(part.lowercased()) {
            // Also dedupe within this single tap if the chip somehow has repeats.
            if !toAdd.contains(where: { $0.lowercased() == part.lowercased() }) {
                toAdd.append(part)
            }
        }
        guard !toAdd.isEmpty else { return }
        withAnimation(.spring(response: 0.25)) {
            mealItems.append(contentsOf: toAdd)
        }
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

            Spacer().frame(height: 4)

            Text("We'll track when you perform best.")
                .font(.synText(13))
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 12)

            TimePickerInput(selectedTime: $liftTime)
        }
    }

    // MARK: - Gap

    @ViewBuilder
    private var gapBlock: some View {
        if liftTime <= mealTime {
            Text("Set lift time after meal time")
                .font(.synText(13))
                .foregroundStyle(SYN.red)
        } else {
            let totalMins = Int(liftTime.timeIntervalSince(mealTime) / 60)
            let hours = totalMins / 60
            let mins = totalMins % 60

            VStack(spacing: 4) {
                Text(gapPhrase(hours: hours, mins: mins))
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(SYN.textDim)

                Text(contextLabel(forMinutes: totalMins).text)
                    .font(.synText(14, weight: .medium))
                    .foregroundStyle(contextLabel(forMinutes: totalMins).color)
            }
        }
    }

    private func gapPhrase(hours: Int, mins: Int) -> String {
        if hours > 0 && mins > 0 { return "\(hours)hr \(mins)min gap" }
        if hours > 0 { return "\(hours)hr gap" }
        return "\(mins)min gap"
    }

    private func contextLabel(forMinutes total: Int) -> (text: String, color: Color) {
        switch total {
        case ..<60:    return ("Still digesting",  SYN.amber)
        case 60...90:  return ("Getting there",     SYN.textDim)
        case 91...180: return ("Sweet spot",        SYN.cyan)
        default:       return ("Fully digested",    SYN.green)
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
