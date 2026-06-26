import SwiftUI

struct S3Setup: View {
    var model: OnboardingModel
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var firstName: String = ""
    @State private var days: Double = 4

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    private var trimmed: String {
        firstName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var isValid: Bool { trimmed.count >= 2 }
    private var count: Int { Int(days) }

    private var savedName: String {
        guard !trimmed.isEmpty else { return "" }
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
    }

    // Which days a typical week fills at a given lifting frequency.
    private func litDays(_ n: Int) -> Set<Int> {
        switch n {
        case 1:  return [2]
        case 2:  return [0, 3]
        case 3:  return [0, 2, 4]
        case 4:  return [0, 1, 3, 4]
        case 5:  return [0, 1, 2, 3, 4]
        case 6:  return [0, 1, 2, 3, 4, 5]
        default: return [0, 1, 2, 3, 4, 5, 6]
        }
    }

    var body: some View {
        ScreenShell(progress: ScreenProgress.s3, onBack: onBack, ambient: false) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 8)

                Text("Lock in your week.")
                    .font(.synDisplay(30, weight: .bold))
                    .foregroundStyle(SYN.text)
                    .kerning(-0.9)
                    .shadow(color: SYN.cyan.opacity(0.25), radius: 12)

                Spacer().frame(height: 10)

                Text("Your name, and how many days you lift.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)

                Spacer().frame(height: 16)

                SpecInput(
                    value: $firstName,
                    placeholder: "Your name",
                    label: "First name",
                    autocap: .words,
                    maxLength: 24,
                    isValid: trimmed.isEmpty ? nil : isValid
                )

                Spacer().frame(height: 22)

                EyebrowText(text: "Lifting days per week")
                    .foregroundStyle(SYN.textFaint)

                Spacer().frame(height: 16)

                weekVisual

                Spacer().frame(height: 18)

                SpecSlider(
                    value: $days,
                    range: 1...7,
                    step: 1,
                    ticks: [1, 2, 3, 4, 5, 6, 7],
                    tickLabels: ["1", "2", "3", "4", "5", "6", "7"]
                )

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } cta: {
            PrimaryButton(title: "Continue", disabled: !isValid) {
                model.firstName = savedName
                UserDefaults.standard.set(savedName, forKey: "userName")
                model.daysPerWeek = count
                UserDefaults.standard.set(count, forKey: "trainingFrequency")
                onNext()
            }
            .scaleEffect(isValid ? 1 : 0.98)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isValid)
        }
        .onAppear {
            firstName = model.firstName
            days = Double(model.daysPerWeek)
        }
    }

    // Live mock week: the chosen number of lifting days light up as the slider
    // moves. Same cell language as the value screen.
    private var weekVisual: some View {
        let lit = litDays(count)
        return HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { idx in
                dayCell(idx, isLit: lit.contains(idx))
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.3, dampingFraction: 0.72), value: count)
    }

    private func dayCell(_ idx: Int, isLit: Bool) -> some View {
        VStack(spacing: 6) {
            Text(dayLabels[idx])
                .font(.synText(11, weight: .semibold))
                .foregroundStyle(isLit ? SYN.cyan : SYN.textFaint)
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isLit ? SYN.cyan.opacity(0.12) : SYN.surface)
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isLit ? SYN.cyan : SYN.border, lineWidth: isLit ? 1.5 : 1)
                if isLit {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SYN.cyan)
                }
            }
            .frame(height: 46)
        }
    }
}

#Preview {
    S3Setup(model: OnboardingModel(), onBack: {}, onNext: {})
        .preferredColorScheme(.dark)
}
