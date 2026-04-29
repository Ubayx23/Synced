import SwiftUI

struct OnboardingFlow: View {
    @State private var step: Int = {
        // Debug helper: launch with `-startStep 7` to deep-link onto a screen.
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-startStep"),
           i + 1 < args.count,
           let n = Int(args[i + 1]) {
            return max(1, min(13, n))
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
                case 5:  S5Hook(onBack: back, onNext: next)
                case 6:  S6Benefits(onBack: back, onNext: next)
                case 7:  S7Goal(model: model, onBack: back, onNext: next)
                case 8:  S8Frequency(model: model, onBack: back, onNext: next)
                case 9:  S9Sleep(model: model, onBack: back, onNext: next)
                case 10: S10Diagnostic(model: model, onBack: back, onNext: next)
                case 11: S11Loading(model: model, onBack: back, onNext: next)
                case 12: S12TierReveal(model: model, onBack: back, onNext: next)
                default: SHome(model: model, onRestart: restart)
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

    private var progress: Double {
        // Per chat1: 8/16/25/33/41/50/58/66/75/91/100
        switch step {
        case 1:  return 0
        case 2:  return 8.0 / 100
        case 3:  return 16.0 / 100
        case 4:  return 25.0 / 100
        case 5:  return 33.0 / 100
        case 6:  return 41.0 / 100
        case 7:  return 50.0 / 100
        case 8:  return 58.0 / 100
        case 9:  return 66.0 / 100
        case 10: return 75.0 / 100
        case 11: return 91.0 / 100
        case 12: return 1.0
        default: return 1.0
        }
    }

    private func next()    { step = min(13, step + 1) }
    private func back()    { step = max(1, step - 1) }
    private func restart() {
        model.reset()
        step = 1
    }
}

/// Static progress helper for screens that want to know their own bar value
/// without pulling in the flow's internals.
enum ScreenProgress {
    static let s2: Double  = 0.08
    static let s3: Double  = 0.16
    static let s4: Double  = 0.25
    static let s5: Double  = 0.33
    static let s6: Double  = 0.41
    static let s7: Double  = 0.50
    static let s8: Double  = 0.58
    static let s9: Double  = 0.66
    static let s10: Double = 0.75
    static let s11: Double = 0.91
    static let s12: Double = 1.00
}
