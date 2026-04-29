import SwiftUI

struct S11Loading: View {
    var model: OnboardingModel
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var progress: Double = 0
    @State private var phase = 0
    @State private var step: Int = 0

    private let checks = [
        "Reading your inputs",
        "Calibrating recovery model",
        "Cross-referencing your cohort",
        "Computing your tier"
    ]

    var body: some View {
        ScreenShell(progress: ScreenProgress.s11, onBack: onBack) {
            VStack(alignment: .center, spacing: 0) {
                EyebrowTag(text: "Syncing data")
                    .phaseFadeUp(phase: phase, delay: 0.05)

                Spacer().frame(height: 24)

                Text("\(Int(progress * 100))%")
                    .font(.synMono(96, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, SYN.cyanSoft],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: SYN.cyan.opacity(0.6), radius: 18)
                    .contentTransition(.numericText(countsDown: false))
                    .animation(.linear, value: progress)

                Spacer().frame(height: 16)

                progressBar
                    .frame(height: 4)
                    .padding(.horizontal, 40)

                Spacer().frame(height: 32)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(checks.enumerated()), id: \.offset) { idx, item in
                        checkRow(text: item, done: idx < step)
                            .phaseSlideLeft(phase: phase, delay: 0.10 + Double(idx) * 0.08)
                    }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
        } cta: {
            PrimaryButton(title: "Reveal my tier", disabled: progress < 0.91) {
                model.computeTier()
                onNext()
            }
        }
        .task {
            withAnimation { phase = 1 }
            await runProgress()
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(SYN.border)
                Capsule()
                    .fill(LinearGradient(colors: [SYN.cyan, SYN.cyanSoft],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * progress)
                    .shadow(color: SYN.cyan.opacity(0.6), radius: 8)
            }
        }
    }

    private func checkRow(text: String, done: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(done ? SYN.cyan.opacity(0.18) : SYN.surface)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(done ? SYN.cyan : SYN.border, lineWidth: 1))
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SYN.cyan)
                }
            }
            Text(text)
                .font(.synText(14))
                .foregroundStyle(done ? SYN.text : SYN.textDim)
            Spacer(minLength: 0)
        }
    }

    private func runProgress() async {
        let target = 0.91
        let duration = 3.0
        let frames = 60.0
        let dt = duration / frames
        let stepProgress = target / frames

        for i in 0..<Int(frames) {
            try? await Task.sleep(nanoseconds: UInt64(dt * 1_000_000_000))
            progress = min(target, Double(i + 1) * stepProgress)
            // Reveal each check at quarter intervals
            if Double(i) / frames > 0.20 && step < 1 { step = 1 }
            if Double(i) / frames > 0.45 && step < 2 { step = 2 }
            if Double(i) / frames > 0.70 && step < 3 { step = 3 }
            if Double(i) / frames > 0.95 && step < 4 { step = 4 }
        }
    }
}
