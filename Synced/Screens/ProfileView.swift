import SwiftUI

private let mockUserName        = "Ubay"
private let mockUserUsername    = "@ubaydev"
private let mockJoinDate        = "April 2026"
private let mockCurrentTier     = "Dialed"
private let mockCurrentTierHex  = "22C55E"
private let mockCurrentScore    = 67
private let mockStreak          = 5
private let mockTotalCheckins   = 12
private let mockWeeksTracked    = 3

struct ProfileView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SYN.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    closeRow
                        .padding(.top, 8)

                    profileHeaderCard
                        .padding(.top, 8)

                    Spacer().frame(height: 24)
                    EyebrowText(text: "Your stats").foregroundStyle(SYN.textFaint)
                    Spacer().frame(height: 16)
                    statsGrid

                    Spacer().frame(height: 24)
                    EyebrowText(text: "Tier history").foregroundStyle(SYN.textFaint)
                    Spacer().frame(height: 16)
                    tierHistory

                    Spacer().frame(height: 24)
                    EyebrowText(text: "Settings").foregroundStyle(SYN.textFaint)
                    Spacer().frame(height: 16)
                    settings

                    Color.clear.frame(height: 32)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.pageH)
            }
        }
    }

    // MARK: - Close row

    private var closeRow: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SYN.textFaint)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Profile header

    private var profileHeaderCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle().fill(SYN.surface)
                    Text(String(mockUserName.prefix(1)).uppercased())
                        .font(.synDisplay(24, weight: .bold))
                        .foregroundStyle(SYN.text)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mockUserName)
                        .font(.synDisplay(20, weight: .bold))
                        .foregroundStyle(SYN.text)
                    Text(mockUserUsername)
                        .font(.synText(14))
                        .foregroundStyle(SYN.textDim)
                    Text("Member since \(mockJoinDate)")
                        .font(.synText(12))
                        .foregroundStyle(SYN.textFaint)
                }
                Spacer()
            }

            Spacer().frame(height: 20)
            Rectangle().fill(SYN.border).frame(height: 1)
            Spacer().frame(height: 20)

            HStack(alignment: .center) {
                Text("CURRENT TIER")
                    .font(.synText(11, weight: .semibold))
                    .tracking(0.88)
                    .foregroundStyle(SYN.textFaint)

                Spacer()

                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: mockCurrentTierHex))
                        .frame(width: 8, height: 8)
                    Text(mockCurrentTier)
                        .font(.synDisplay(15, weight: .semibold))
                        .foregroundStyle(Color(hex: mockCurrentTierHex))
                    Text("\(mockCurrentScore)")
                        .font(.synMono(15, weight: .bold))
                        .foregroundStyle(SYN.text)
                    Text("pts")
                        .font(.synText(12))
                        .foregroundStyle(SYN.textDim)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(SYN.surfaceHi)
        )
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: cols, alignment: .leading, spacing: 12) {
            StatCard(value: "\(mockStreak)",
                     valueFont: .synMono(28, weight: .bold),
                     valueColor: SYN.text,
                     label: "Day streak",
                     iconName: "flame.fill",
                     iconColor: SYN.amber)
            StatCard(value: "\(mockTotalCheckins)",
                     valueFont: .synMono(28, weight: .bold),
                     valueColor: SYN.text,
                     label: "Total check-ins",
                     iconName: "checkmark.circle.fill",
                     iconColor: SYN.green)
            StatCard(value: "\(mockWeeksTracked)",
                     valueFont: .synMono(28, weight: .bold),
                     valueColor: SYN.text,
                     label: "Weeks tracked",
                     iconName: "calendar",
                     iconColor: SYN.textDim)
            StatCard(value: mockCurrentTier,
                     valueFont: .synDisplay(20, weight: .semibold),
                     valueColor: Color(hex: mockCurrentTierHex),
                     label: "Best tier",
                     iconName: "trophy.fill",
                     iconColor: SYN.amber)
        }
    }

    // MARK: - Tier history

    private var tierHistory: some View {
        VStack(spacing: 8) {
            TierHistoryRow(label: "This week",   labelColor: SYN.text,    tier: "Dialed", tierHex: "22C55E")
            TierHistoryRow(label: "Last week",   labelColor: SYN.textDim, tier: "Active", tierHex: "FFFFFF")
            TierHistoryRow(label: "2 weeks ago", labelColor: SYN.textDim, tier: "Active", tierHex: "FFFFFF")
        }
    }

    // MARK: - Settings

    private var settings: some View {
        VStack(spacing: 8) {
            SettingsRow(icon: "bell.fill", iconColor: SYN.textDim, label: "Notifications", labelColor: SYN.text, action: {})
            SettingsRow(icon: "person.fill", iconColor: SYN.textDim, label: "Edit profile", labelColor: SYN.text, action: {})
            SettingsRow(
                icon: "rectangle.portrait.and.arrow.right",
                iconColor: SYN.textDim,
                label: "Log out",
                labelColor: SYN.text,
                action: {
                    Task { await session.signOut() }
                }
            )
            SettingsRow(
                icon: "arrow.right.circle.fill",
                iconColor: Color(hex: "EF4444"),
                label: "Reset onboarding",
                labelColor: Color(hex: "EF4444"),
                action: {
                    let keys = [
                        "hasCompletedOnboarding",
                        "userName",
                        "userAge",
                        "trainingGoal",
                        "trainingFrequency",
                        "sleepBaseline",
                    ]
                    for key in keys {
                        UserDefaults.standard.removeObject(forKey: key)
                    }
                    Task { await session.signOut() }
                }
            )
        }
    }
}

// MARK: - Components

private struct StatCard: View {
    let value: String
    let valueFont: Font
    let valueColor: Color
    let label: String
    let iconName: String
    let iconColor: Color

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(valueFont)
                    .foregroundStyle(valueColor)
                Text(label)
                    .font(.synText(12))
                    .foregroundStyle(SYN.textDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: iconName)
                .font(.system(size: 16))
                .foregroundStyle(iconColor)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SYN.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SYN.border, lineWidth: 1)
        )
    }
}

private struct TierHistoryRow: View {
    let label: String
    let labelColor: Color
    let tier: String
    let tierHex: String

    var body: some View {
        HStack {
            Text(label)
                .font(.synText(14))
                .foregroundStyle(labelColor)
            Spacer()
            HStack(spacing: 8) {
                Circle().fill(Color(hex: tierHex)).frame(width: 8, height: 8)
                Text(tier)
                    .font(.synDisplay(14, weight: .semibold))
                    .foregroundStyle(Color(hex: tierHex))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(SYN.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(SYN.border, lineWidth: 1)
        )
    }
}

private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let labelColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
                    .frame(width: 22)
                Text(label)
                    .font(.synText(15))
                    .foregroundStyle(labelColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SYN.textFaint)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(SYN.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(SYN.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfileView()
        .environment(SessionStore())
        .preferredColorScheme(.dark)
}
