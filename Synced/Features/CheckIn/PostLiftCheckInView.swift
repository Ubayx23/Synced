import SwiftUI

struct PostLiftCheckInView: View {
    @Binding var isComplete: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: Int = 1
    @State private var sessionRating: Int = 0
    @State private var performanceVsExpectation: String = ""
    @State private var sessionDuration: String = ""
    @State private var sessionNotes: String = ""

    @State private var ctaPulse: Double = 1.0

    private let totalSteps = 2

    var body: some View {
        ZStack {
            SYN.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, Spacing.pageH)
                    .padding(.top, 16)

                Spacer().frame(height: 24)

                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomCTA
                    .padding(.horizontal, Spacing.pageH)
                    .padding(.bottom, 48)
            }
        }
        .onChange(of: currentStep) { _, new in
            if new == totalSteps {
                ctaPulse = 0.96
                withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.05)) {
                    ctaPulse = 1.0
                }
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .center) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SYN.textFaint)
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 8) {
                ForEach(1...totalSteps, id: \.self) { idx in
                    Circle()
                        .fill(idx <= currentStep ? SYN.cyan : SYN.border)
                        .frame(width: 6, height: 6)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: currentStep)

            Spacer()

            Text("\(currentStep) of \(totalSteps)")
                .font(.synText(13))
                .foregroundStyle(SYN.textDim)
                .frame(width: 44, alignment: .trailing)
        }
    }

    // MARK: - Step content

    @ViewBuilder
    private var stepContent: some View {
        ZStack {
            Group {
                switch currentStep {
                case 1: PerformanceStep(sessionRating: $sessionRating,
                                        performanceVsExpectation: $performanceVsExpectation)
                default: SessionDetailsStep(sessionDuration: $sessionDuration,
                                            sessionNotes: $sessionNotes)
                }
            }
            .id(currentStep)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .animation(.easeInOut(duration: 0.25), value: currentStep)
    }

    // MARK: - CTA

    private var ctaLabel: String {
        currentStep == totalSteps ? "Save session" : "Continue"
    }

    private var canAdvance: Bool {
        switch currentStep {
        case 1: return sessionRating != 0 && !performanceVsExpectation.isEmpty
        default: return true
        }
    }

    private var bottomCTA: some View {
        PrimaryButton(title: ctaLabel, action: advance)
            .opacity(canAdvance ? 1 : 0.5)
            .disabled(!canAdvance)
            .allowsHitTesting(canAdvance)
            .scaleEffect(currentStep == totalSteps ? ctaPulse : 1.0)
    }

    private func advance() {
        if currentStep == totalSteps {
            handleComplete()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { currentStep += 1 }
        }
    }

    private func handleComplete() {
        isComplete = true
        dismiss()
    }
}
