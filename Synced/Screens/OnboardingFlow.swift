import SwiftUI

struct OnboardingFlow: View {
    @State private var step: Int = {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-startStep"),
           i + 1 < args.count,
           let n = Int(args[i + 1]) {
            return max(1, min(10, n))
        }
        return 1
    }()
    @State private var model = OnboardingModel()

    var body: some View {
        ZStack {
            ScreenBackground()

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

    private func next() { step = min(10, step + 1) }
    private func back() { step = max(1, step - 1) }

    /// Tier-reveal CTA — terminal step. Flips the persistent flag and lets
    /// `RootView` swap to `MainTabView`.
    private func finish() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

/// Progress values per route step. Step 1 (welcome) and step 10 (tier reveal)
/// hide the bar entirely; the rest show 10% increments rising to 100% on
/// notifications.
enum ScreenProgress {
    static let s2: Double  = 0.10
    static let s3: Double  = 0.20
    static let s4: Double  = 0.30
    static let s5: Double  = 0.40
    static let s6: Double  = 0.50
    static let s7: Double  = 0.60
    static let s8: Double  = 0.70
    static let s9: Double  = 1.00
}
