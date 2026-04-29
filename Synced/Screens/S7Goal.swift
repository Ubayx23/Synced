import SwiftUI

struct S7Goal: View {
    var model: OnboardingModel
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var phase = 0
    @State private var selected: Goal? = nil

    var body: some View {
        ScreenShell(progress: ScreenProgress.s7, onBack: onBack) {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowTag(text: "Your primary goal")
                    .phaseFadeUp(phase: phase, delay: 0.05)

                Spacer().frame(height: 18)

                (Text("What's your ")
                    .foregroundColor(.white)
                 + Text("training")
                    .foregroundColor(SYN.cyan)
                 + Text(" focus?").foregroundColor(.white))
                    .font(.synDisplay(30, weight: .bold))
                    .kerning(-0.9)
                    .lineSpacing(2)
                    .shadow(color: SYN.cyan.opacity(0.25), radius: 12)
                    .phaseFadeUp(phase: phase, delay: 0.18)

                Spacer().frame(height: 28)

                VStack(spacing: 10) {
                    ForEach(Array(Goal.allCases.enumerated()), id: \.element.id) { idx, goal in
                        SelectableCard(
                            title: goal.rawValue,
                            height: 64,
                            selected: selected == goal
                        ) {
                            selected = goal
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        .phaseFadeUp(phase: phase, delay: 0.32 + Double(idx) * 0.07)
                    }
                }

                Spacer()
            }
        } cta: {
            PrimaryButton(title: "Continue", disabled: selected == nil) {
                model.goal = selected
                onNext()
            }
        }
        .onAppear { selected = model.goal }
        .task { withAnimation { phase = 1 } }
    }
}
