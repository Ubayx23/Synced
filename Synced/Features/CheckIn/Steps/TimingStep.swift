import SwiftUI

struct TimingStep: View {
    @Binding var mealTime: Date
    @Binding var liftTime: Date

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowText(text: "Step 3 of 3")
                    .foregroundStyle(SYN.textFaint)

                Spacer().frame(height: 24)

                Text("When did you eat?")
                    .font(.synDisplay(28, weight: .bold))
                    .foregroundStyle(SYN.text)

                Spacer().frame(height: 8)

                Text("And when are you lifting?")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)

                Spacer().frame(height: 40)

                mealTimeBlock

                Spacer().frame(height: 20)

                gapCard
                    .frame(maxWidth: .infinity)

                Spacer().frame(height: 24)

                divider

                Spacer().frame(height: 24)

                liftTimeBlock

                Color.clear.frame(height: 32)
            }
            .padding(.horizontal, Spacing.pageH)
        }
    }

    // MARK: - Meal time

    private var mealTimeBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "Meal time")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 12)

            TimePickerInput(selectedTime: $mealTime)
        }
    }

    // MARK: - Gap card

    @ViewBuilder
    private var gapCard: some View {
        VStack(spacing: 4) {
            if liftTime <= mealTime {
                Text("Set lift time after meal time")
                    .font(.synText(14, weight: .medium))
                    .foregroundStyle(SYN.red)
            } else {
                let totalMins = Int(liftTime.timeIntervalSince(mealTime) / 60)
                let hours = totalMins / 60
                let mins = totalMins % 60

                Text(gapPhrase(hours: hours, mins: mins))
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(SYN.textDim)

                Text(contextLabel(forMinutes: totalMins).text)
                    .font(.synText(14, weight: .semibold))
                    .foregroundStyle(contextLabel(forMinutes: totalMins).color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SYN.surfaceHi)
        )
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

    // MARK: - Lift time

    private var liftTimeBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "Lift time")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 4)

            Text("We track which times you perform best.")
                .font(.synText(13))
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 12)

            TimePickerInput(selectedTime: $liftTime)
        }
    }
}
