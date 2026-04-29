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

            TimePickerInput(selectedTime: $mealTime)

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
            Text(phrase(hours: hours, minutes: minutes))
                .font(.synText(14))
                .foregroundStyle(SYN.textDim)
        }
    }

    private func phrase(hours: Int, minutes: Int) -> String {
        if hours == 0 && minutes == 0 {
            return "That's just now"
        }
        if hours == 0 {
            let unit = minutes == 1 ? "min" : "mins"
            return "That's \(minutes) \(unit) before your lift"
        }
        let hUnit = hours == 1 ? "hr" : "hrs"
        if minutes == 0 {
            return "That's \(hours) \(hUnit) before your lift"
        }
        let mUnit = minutes == 1 ? "min" : "mins"
        return "That's \(hours) \(hUnit) \(minutes) \(mUnit) before your lift"
    }
}

extension MealTimingStep {
    /// Formats a meal time as "h:mm a" (e.g. "1:30 PM"). Used by the parent
    /// view when persisting the answer on Continue.
    static func formatted(_ date: Date) -> String {
        formatter.string(from: date)
    }
}
