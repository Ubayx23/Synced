import SwiftUI
import UIKit

/// Profile sheet: daily reminder settings and sign out.
struct ProfileSheet: View {
    @Environment(SessionStore.self) private var session
    @State private var signingOut = false

    @AppStorage(ReminderScheduler.Keys.enabled) private var reminderEnabled = false
    @AppStorage(ReminderScheduler.Keys.hour) private var reminderHour = ReminderScheduler.defaultHour
    @AppStorage(ReminderScheduler.Keys.minute) private var reminderMinute = ReminderScheduler.defaultMinute
    /// Shown when iOS will not deliver notifications for Synced.
    @State private var notificationsBlocked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Profile")
                .font(.synDisplay(22, weight: .bold))
                .foregroundStyle(SYN.text)
                .kerning(-0.4)

            Spacer().frame(height: Spacing.lg)

            EyebrowText(text: "Reminders")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: Spacing.m)

            remindersCard

            Spacer().frame(height: Spacing.xl)

            SecondaryButton(title: signingOut ? "Signing out" : "Sign out") {
                guard !signingOut else { return }
                signingOut = true
                Task { await session.signOut() }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.pageH)
        .padding(.top, Spacing.xl)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(SYN.bg)
        .presentationCornerRadius(Radius.card * 2)
        .task { await syncWithSystemPermission() }
        .onChange(of: reminderHour) { _, _ in Task { await ReminderScheduler.reschedule() } }
        .onChange(of: reminderMinute) { _, _ in Task { await ReminderScheduler.reschedule() } }
    }

    // MARK: - Reminders

    private var remindersCard: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Toggle(isOn: Binding(get: { reminderEnabled }, set: setReminder)) {
                Text("Daily reminder")
                    .font(.synText(16, weight: .medium))
                    .foregroundStyle(SYN.text)
            }
            .tint(SYN.cyan)

            if reminderEnabled {
                HStack {
                    Text("Remind me at")
                        .font(.synText(15))
                        .foregroundStyle(SYN.textDim)
                    Spacer()
                    DatePicker("Remind me at", selection: reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(SYN.cyan)
                }

                Text("We'll ping you if you haven't logged today's session yet.")
                    .font(.synText(13))
                    .foregroundStyle(SYN.textFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if notificationsBlocked {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Notifications are off in Settings. Enable them in iOS Settings to get reminders.")
                        .font(.synText(13))
                        .foregroundStyle(SYN.textDim)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.synText(13, weight: .semibold))
                    .foregroundStyle(SYN.cyan)
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(SYN.surface.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(SYN.border, lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.2), value: reminderEnabled)
        .animation(.easeOut(duration: 0.2), value: notificationsBlocked)
    }

    /// The picker edits a Date, but only hour and minute are stored, so the
    /// reminder keeps its clock time across timezones.
    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: Date()
                ) ?? Date()
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                reminderHour = parts.hour ?? ReminderScheduler.defaultHour
                reminderMinute = parts.minute ?? ReminderScheduler.defaultMinute
            }
        )
    }

    /// Turning on asks iOS for permission here, the first moment the user has
    /// said they want reminders. A denial flips the toggle back off.
    private func setReminder(_ on: Bool) {
        guard on else {
            reminderEnabled = false
            notificationsBlocked = false
            Task { await ReminderScheduler.cancelAll() }
            return
        }
        reminderEnabled = true
        Task {
            let allowed = await ReminderScheduler.requestPermissionIfNeeded()
            await MainActor.run {
                reminderEnabled = allowed
                notificationsBlocked = !allowed
            }
            if allowed { await ReminderScheduler.reschedule() }
        }
    }

    /// If notifications were turned off in iOS Settings since the reminder
    /// was enabled, show the toggle as off with the Settings hint.
    private func syncWithSystemPermission() async {
        let status = await ReminderScheduler.authorizationStatus()
        guard reminderEnabled, status == .denied else { return }
        reminderEnabled = false
        notificationsBlocked = true
        await ReminderScheduler.cancelAll()
    }
}
