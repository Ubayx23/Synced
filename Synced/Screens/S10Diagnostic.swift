import SwiftUI

struct S10Diagnostic: View {
    var model: OnboardingModel
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var phase = 0
    @State private var selected: DiagnosticOption? = nil

    var body: some View {
        ScreenShell(progress: ScreenProgress.s10, onBack: onBack) {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowTag(text: "Friction diagnostic")
                    .phaseFadeUp(phase: phase, delay: 0.05)

                Spacer().frame(height: 18)

                (Text("Where are your ")
                    .foregroundColor(.white)
                 + Text("worst days")
                    .foregroundColor(SYN.cyan)
                 + Text(" coming from?").foregroundColor(.white))
                    .font(.synDisplay(28, weight: .bold))
                    .kerning(-0.9)
                    .lineSpacing(2)
                    .shadow(color: SYN.cyan.opacity(0.25), radius: 12)
                    .phaseFadeUp(phase: phase, delay: 0.18)

                Spacer().frame(height: 28)

                VStack(spacing: 10) {
                    ForEach(Array(DiagnosticOption.allCases.enumerated()), id: \.element.id) { idx, opt in
                        SelectableCard(
                            title: opt.rawValue,
                            height: 64,
                            selected: selected == opt
                        ) {
                            selected = opt
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        .phaseFadeUp(phase: phase, delay: 0.30 + Double(idx) * 0.07)
                    }
                }

                Spacer()
            }
        } cta: {
            PrimaryButton(title: "Continue", disabled: selected == nil) {
                model.diagnostic = selected
                onNext()
            }
        }
        .onAppear { selected = model.diagnostic }
        .task { withAnimation { phase = 1 } }
    }
}
