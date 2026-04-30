import SwiftUI
import UserNotifications

struct S9Notifications: View {
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var phase = 0
    @State private var requesting = false

    var body: some View {
        ScreenShell(progress: ScreenProgress.s9, onBack: onBack, ambient: false) {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowTag(text: "Stay on track")
                    .phaseFadeUp(phase: phase, delay: 0.05)

                Spacer().frame(height: 16)

                Text("We'll remind you to check in.")
                    .font(.synDisplay(28, weight: .bold))
                    .foregroundStyle(.white)
                    .kerning(-0.9)
                    .shadow(color: SYN.cyan.opacity(0.25), radius: 12)
                    .phaseFadeUp(phase: phase, delay: 0.18)

                Spacer().frame(height: 10)

                Text("Before and after each session. Two taps each time.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)
                    .phaseFadeUp(phase: phase, delay: 0.26)

                Spacer().frame(height: 32)

                VStack(spacing: 12) {
                    notificationCard(
                        title: "Time to log your pre-lift",
                        body: "30 seconds before you start. Log sleep, food, and energy.",
                        timestamp: "now"
                    )
                    notificationCard(
                        title: "How did the session go?",
                        body: "Log your post-lift to complete today's check-in.",
                        timestamp: "2h ago"
                    )
                }
                .phaseFadeUp(phase: phase, delay: 0.34)

                Spacer().frame(height: 16)

                Text("You control the timing in settings.")
                    .font(.synText(13))
                    .foregroundStyle(SYN.textFaint)
                    .frame(maxWidth: .infinity)
                    .phaseFadeUp(phase: phase, delay: 0.45)

                Spacer()
            }
        } cta: {
            VStack(spacing: 12) {
                PrimaryButton(title: "Allow notifications", disabled: requesting) {
                    requestPermission()
                }
                TextLinkButton(title: "Maybe later", action: onNext)
            }
        }
        .task { withAnimation { phase = 1 } }
    }

    // MARK: - Mock notification card

    private func notificationCard(title: String, body: String, timestamp: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(SYN.cyan.opacity(0.18))
                .overlay(
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SYN.cyan)
                )
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("SYNCED")
                        .font(.synText(11, weight: .semibold))
                        .tracking(0.88)
                        .foregroundStyle(SYN.textFaint)
                    Spacer()
                    Text(timestamp)
                        .font(.synText(11))
                        .foregroundStyle(SYN.textFaint)
                }
                Text(title)
                    .font(.synDisplay(15, weight: .semibold))
                    .foregroundStyle(SYN.text)
                Text(body)
                    .font(.synText(13))
                    .foregroundStyle(SYN.textDim)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(SYN.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(SYN.border, lineWidth: 1)
        )
    }

    // MARK: - Permission

    private func requestPermission() {
        requesting = true
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { _, _ in
            // Advance regardless of grant/deny — user already tapped Allow.
            DispatchQueue.main.async {
                requesting = false
                onNext()
            }
        }
    }
}
