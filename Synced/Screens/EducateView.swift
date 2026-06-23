import SwiftUI

struct EducateView: View {
    var body: some View {
        ZStack {
            SYN.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                Image(systemName: "book.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(SYN.cyan)
                Spacer().frame(height: 20)
                Text("Learn")
                    .font(.synDisplay(28, weight: .bold))
                    .foregroundStyle(SYN.text)
                Spacer().frame(height: 8)
                EyebrowText(text: "Coming soon")
                    .foregroundStyle(SYN.textFaint)
                Spacer().frame(height: 24)
                Text("Short, simple lessons on sleep, fuel, hydration, and recovery, tied to your data. Designed to teach you what your body actually responds to.")
                    .font(.synText(14))
                    .foregroundStyle(SYN.textDim)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                Spacer()
            }
            .padding(.horizontal, Spacing.pageH)
        }
    }
}

#Preview {
    EducateView()
        .preferredColorScheme(.dark)
}
