import SwiftUI

struct MealTimingStep: View {
    @Binding var mealTime: Date

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "Step 4 of 5")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 24)

            Text("What time did you eat?")
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)

            Spacer().frame(height: 8)

            Text("We'll calculate the gap to your lift.")
                .font(.synText(15))
                .foregroundStyle(SYN.textDim)

            Spacer().frame(height: 64)

            DatePicker("", selection: $mealTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .frame(maxWidth: .infinity)

            Spacer().frame(height: 16)

            gapLabel
                .frame(maxWidth: .infinity)

            Spacer()
        }
        .padding(.horizontal, Spacing.pageH)
    }

    @ViewBuilder
    private var gapLabel: some View {
        let now = Date()
        if mealTime > now {
            Text("Select a time in the past")
                .font(.synText(14))
                .foregroundStyle(SYN.red)
        } else {
            let interval = Int(now.timeIntervalSince(mealTime))
            let hours = interval / 3600
            let minutes = (interval % 3600) / 60
            Text("That's \(hours) hrs \(minutes) mins before your lift")
                .font(.synText(14))
                .foregroundStyle(SYN.textDim)
        }
    }
}

extension MealTimingStep {
    /// Formats a meal time as "h:mm a" (e.g. "1:30 PM"). Used by the parent
    /// view when persisting the answer on Continue.
    static func formatted(_ date: Date) -> String {
        formatter.string(from: date)
    }
}
