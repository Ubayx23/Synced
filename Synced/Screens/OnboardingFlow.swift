import SwiftUI

struct OnboardingFlow: View {
    @Environment(SessionStore.self) private var session
    @State private var step: Int = {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-startStep"),
           i + 1 < args.count,
           let n = Int(args[i + 1]) {
            return max(1, min(11, n))
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
                case 4:  S4Age(model: model, onBack: back, onNext: next)
                case 5:  S7Goal(model: model, onBack: back, onNext: next)
                case 6:  S8Frequency(model: model, onBack: back, onNext: next)
                case 7:  S9Sleep(model: model, onBack: back, onNext: next)
                case 8:  S8CheckInLoop(onBack: back, onNext: next)
                case 9:  S9Notifications(onBack: back, onNext: next)
                case 10: SignUpView(onBack: back, onSuccess: next)
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

    private func next() { step = min(11, step + 1) }
    private func back() { step = max(1, step - 1) }

    /// Tier-reveal CTA — terminal step. Flips the session phase so
    /// `RootView` swaps to `MainTabView`.
    private func finish() {
        session.markSignedIn()
    }
}

/// Progress values per onboarding step. Steps 1 (welcome) and 11 (tier reveal)
/// hide the bar entirely; steps 2 to 10 fill evenly from 10% to 90%.
enum ScreenProgress {
    static let total = 11
    static let signUpStep = 10

    private static func at(_ step: Int) -> Double {
        Double(step - 1) / Double(total - 1)
    }

    static let s2 = at(2)
    static let s3 = at(3)
    static let s4 = at(4)
    static let s5 = at(5)
    static let s6 = at(6)
    static let s7 = at(7)
    static let s8 = at(8)
    static let s9 = at(9)
    static let signUp = at(signUpStep)
}
