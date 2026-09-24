import SwiftUI

/// Placeholder profile sheet. For now it only exposes sign out.
struct ProfileSheet: View {
    @Environment(SessionStore.self) private var session
    @State private var signingOut = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Profile")
                .font(.synDisplay(22, weight: .bold))
                .foregroundStyle(SYN.text)
                .kerning(-0.4)

            Spacer().frame(height: Spacing.lg)

            SecondaryButton(title: signingOut ? "Signing out" : "Sign out") {
                guard !signingOut else { return }
                signingOut = true
                Task { await session.signOut() }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.pageH)
        .padding(.top, Spacing.xl)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(SYN.bg)
        .presentationCornerRadius(Radius.card * 2)
    }
}
