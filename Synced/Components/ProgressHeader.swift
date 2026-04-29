import SwiftUI

/// Top-of-screen header — back chevron on the left + thin progress bar to its right.
/// Sits below the safe-area top with extra clearance so it never collides with
/// the status bar / dynamic island (per chat1 fix).
struct ProgressHeader: View {
    var progress: Double
    var onBack: () -> Void
    var showBack: Bool = true

    var body: some View {
        HStack(spacing: 16) {
            if showBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(SYN.textDim)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 32, height: 32)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(SYN.border.opacity(0.7))
                        .frame(height: 4)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [SYN.cyan, SYN.cyanSoft],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, min(geo.size.width, geo.size.width * progress)),
                               height: 4)
                        .shadow(color: SYN.cyan.opacity(0.55), radius: 6, y: 0)
                        .animation(.easeOut(duration: 0.5), value: progress)
                }
                .frame(height: 4)
            }
            .frame(height: 4)
        }
        .padding(.horizontal, Spacing.pageH)
        .padding(.top, 12)
    }
}
