import SwiftUI

struct OnboardingFlow: View {
    @Environment(SessionStore.self) private var session
    @State private var step: Int = {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-startStep"),
           i + 1 < args.count,
           let n = Int(args[i + 1]) {
            return max(1, min(6, n))
        }
        return 1
    }()
    @State private var model = OnboardingModel()

    var body: some View {
        ZStack {
            SYN.bg.ignoresSafeArea()

            Group {
                switch step {
                case 1:  S1Welcome(onNext: next)
                case 2:  S2Value(onBack: back, onNext: next)
                case 3:  S3Name(model: model, onBack: back, onNext: next)
                case 4:  S8Frequency(model: model, onBack: back, onNext: next)
                case 5:  SignUpView(onBack: back, onSuccess: next)
                default: S12TierReveal(model: model, onBack: back, onNext: finish)
                }
            }
            .id(step)
            .transition(
                .asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 8)),
                    removal:   .opacity
                )
            )
        }
        .environment(model)
        .animation(.easeOut(duration: 0.32), value: step)
    }

    private func next() { step = min(6, step + 1) }
    private func back() { step = max(1, step - 1) }

    /// Tier-reveal CTA — terminal step. Flips the session phase so
    /// `RootView` swaps to `MainTabView`.
    private func finish() {
        session.markSignedIn()
    }
}

/// Progress values per onboarding step. Step 1 (welcome) and step 6 (tier
/// reveal) hide the bar entirely; steps 2 to 5 fill evenly across the flow.
/// s4 is used by S8Frequency (now step 4). s5, s7, s8, and s9 are retained
/// only so the parked onboarding screens (S7Goal, S9Sleep, S8CheckInLoop,
/// S9Notifications) still compile; those screens are no longer in the flow.
enum ScreenProgress {
    static let total = 6
    static let signUpStep = 5

    private static func at(_ step: Int) -> Double {
        Double(step - 1) / Double(total - 1)
    }

    static let s2 = at(2)
    static let s3 = at(3)
    static let s4 = at(4)
    static let s5 = at(5)
    static let s7 = at(7)
    static let s8 = at(8)
    static let s9 = at(9)
    static let signUp = at(signUpStep)
}
