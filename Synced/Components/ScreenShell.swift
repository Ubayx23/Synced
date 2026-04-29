import SwiftUI

/// Wraps a screen body with: ambient glow, an optional progress header, and a
/// bottom CTA section pinned 48pt above the safe-area bottom.
///
/// Most screens look like:
/// ```
/// ScreenShell(progress: ScreenProgress.s2, onBack: onBack) {
///     screen body…
/// } cta: {
///     PrimaryButton(title: "Continue") { onNext() }
/// }
/// ```
struct ScreenShell<Content: View, CTAContent: View>: View {
    var progress: Double?           // nil → no header (e.g. Welcome)
    var onBack: (() -> Void)?
    var ambient: Bool = true
    @ViewBuilder var content: Content
    @ViewBuilder var cta: CTAContent

    var body: some View {
        ZStack {
            if ambient { AmbientGlow().ignoresSafeArea() }

            VStack(spacing: 0) {
                if let progress, let onBack {
                    ProgressHeader(progress: progress, onBack: onBack)
                    Spacer().frame(height: 24)
                } else {
                    Spacer().frame(height: 12)
                }

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, Spacing.pageH)

                cta
                    .padding(.horizontal, Spacing.pageH)
                    .padding(.bottom, 48)
            }
        }
    }
}

extension ScreenShell where CTAContent == EmptyView {
    init(progress: Double?,
         onBack: (() -> Void)?,
         ambient: Bool = true,
         @ViewBuilder content: () -> Content)
    {
        self.progress = progress
        self.onBack = onBack
        self.ambient = ambient
        self.content = content()
        self.cta = EmptyView()
    }
}
