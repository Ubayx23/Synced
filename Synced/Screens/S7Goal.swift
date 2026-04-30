import SwiftUI

struct S7Goal: View {
    var model: OnboardingModel
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var phase = 0
    @State private var selected: Goal? = nil

    var body: some View {
        ScreenShell(progress: ScreenProgress.s5, onBack: onBack, ambient: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("What are you training for?")
                    .font(.synDisplay(30, weight: .bold))
                    .foregroundStyle(SYN.text)
                    .kerning(-0.9)
                    .lineSpacing(2)
                    .shadow(color: SYN.cyan.opacity(0.25), radius: 12)
                    .phaseFadeUp(phase: phase, delay: 0.18)

                Spacer().frame(height: 12)

                Text("Synced tracks whether your habits are moving you toward this.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)
                    .phaseFadeUp(phase: phase, delay: 0.26)

                Spacer().frame(height: 24)

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
                if let g = selected {
                    UserDefaults.standard.set(g.rawValue, forKey: "trainingGoal")
                }
                onNext()
            }
        }
        .onAppear { selected = model.goal }
        .task { withAnimation { phase = 1 } }
    }
}
