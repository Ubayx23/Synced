import SwiftUI

/// Drives a single Int phase that flips from 0 → 1 after `delay` seconds.
/// Children read `phase` and apply opacity/offset transitions with their own
/// per-element delays for a staggered reveal.
@MainActor
final class PhaseDriver: ObservableObject {
    @Published var phase: Int = 0

    func start(after delay: TimeInterval = 0) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            withAnimation(.easeOut(duration: 0.7)) { self.phase = 1 }
        }
    }
}

extension View {
    /// Apply staggered fade-up on `phase >= 1`. `delay` is in seconds.
    func phaseFadeUp(phase: Int, delay: Double = 0, distance: CGFloat = 10) -> some View {
        self.opacity(phase >= 1 ? 1 : 0)
            .offset(y: phase >= 1 ? 0 : distance)
            .animation(.easeOut(duration: 0.7).delay(delay), value: phase)
    }

    /// Slide-in-from-left used by lists.
    func phaseSlideLeft(phase: Int, delay: Double = 0, distance: CGFloat = 32) -> some View {
        self.opacity(phase >= 1 ? 1 : 0)
            .offset(x: phase >= 1 ? 0 : -distance)
            .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(delay), value: phase)
    }
}

/// Cyan gradient text (white→cyan) used for the highlight word in headlines.
struct GradientHighlight: View {
    let text: String
    let font: Font

    var body: some View {
        Text(text)
            .font(font)
            .overlay(
                LinearGradient(colors: [SYN.cyan, SYN.cyanSoft],
                               startPoint: .top, endPoint: .bottom)
            )
            .mask(Text(text).font(font))
            .shadow(color: SYN.cyan.opacity(0.5), radius: 12)
    }
}
