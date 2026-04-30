import SwiftUI

struct MockFriend: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let username: String
    let score: Int
    let tier: String
    let tierColor: String
    let isCurrentUser: Bool
}

private let mockLeaderboard: [MockFriend] = [
    MockFriend(rank: 1, name: "Marcus", username: "@ironmk",  score: 91, tier: "Synced",  tierColor: "00E5FF", isCurrentUser: false),
    MockFriend(rank: 2, name: "Ubay",   username: "@ubaydev", score: 67, tier: "Dialed",  tierColor: "22C55E", isCurrentUser: true),
    MockFriend(rank: 3, name: "Jordan", username: "@jfit",    score: 54, tier: "Active",  tierColor: "FFFFFF", isCurrentUser: false),
    MockFriend(rank: 4, name: "Tariq",  username: "@tlifts",  score: 38, tier: "Cooked",  tierColor: "5A5A60", isCurrentUser: false),
]

struct LeaderboardView: View {
    private var friends: [MockFriend] { mockLeaderboard }
    private var hasFriends: Bool { friends.contains { !$0.isCurrentUser } }

    var body: some View {
        ZStack {
            SYN.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 16)

                    Spacer().frame(height: 8)

                    Text("This week's rankings")
                        .font(.synText(14))
                        .foregroundStyle(SYN.textDim)

                    Spacer().frame(height: 4)

                    Text("Resets Sunday at midnight")
                        .font(.synText(12))
                        .foregroundStyle(SYN.textFaint)

                    if hasFriends {
                        Spacer().frame(height: 24)
                        LazyVStack(spacing: 8) {
                            ForEach(friends) { friend in
                                LeaderboardRow(friend: friend)
                            }
                        }
                    } else {
                        emptyState
                            .padding(.top, 80)
                    }

                    Color.clear.frame(height: 32)
                }
                .padding(.horizontal, Spacing.pageH)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Leaderboard")
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)
            Spacer()
            invitePill
        }
    }

    private var invitePill: some View {
        Button(action: { /* future: invite sheet */ }) {
            Text("Invite friends")
                .font(.synText(13, weight: .medium))
                .foregroundStyle(SYN.cyan)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(SYN.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(SYN.cyan, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 40))
                .foregroundStyle(SYN.border)
            Spacer().frame(height: 16)
            Text("No friends yet")
                .font(.synDisplay(17, weight: .semibold))
                .foregroundStyle(SYN.text)
            Spacer().frame(height: 8)
            Text("Invite your gym group to compete")
                .font(.synText(14))
                .foregroundStyle(SYN.textDim)
            Spacer().frame(height: 24)
            PrimaryButton(title: "Invite friends") { /* future */ }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct LeaderboardRow: View {
    let friend: MockFriend

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("\(friend.rank)")
                .font(.synMono(18, weight: .bold))
                .foregroundStyle(rankColor)
                .frame(width: 24, alignment: .leading)

            Spacer().frame(width: 16)

            ZStack {
                Circle()
                    .fill(SYN.surfaceHi)
                Text(initials)
                    .font(.synDisplay(16, weight: .semibold))
                    .foregroundStyle(SYN.text)
            }
            .frame(width: 40, height: 40)

            Spacer().frame(width: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.synDisplay(15, weight: .semibold))
                    .foregroundStyle(SYN.text)
                Text(friend.username)
                    .font(.synText(12))
                    .foregroundStyle(SYN.textDim)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(friend.score)")
                    .font(.synMono(20, weight: .bold))
                    .foregroundStyle(SYN.text)
                Text(friend.tier.uppercased())
                    .font(.synText(11, weight: .semibold))
                    .tracking(0.88) // ~0.08em at 11pt
                    .foregroundStyle(Color(hex: friend.tierColor))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(friend.isCurrentUser ? SYN.surfaceHi : SYN.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(friend.isCurrentUser ? SYN.cyan : .clear, lineWidth: 1)
        )
        .shadow(color: friend.isCurrentUser ? SYN.cyan.opacity(0.20) : .clear, radius: 12)
    }

    private var initials: String {
        String(friend.name.prefix(1)).uppercased()
    }

    private var rankColor: Color {
        switch friend.rank {
        case 1: return SYN.amber
        case 2: return SYN.textDim
        case 3: return SYN.bronze
        default: return SYN.textFaint
        }
    }
}

#Preview {
    LeaderboardView()
        .preferredColorScheme(.dark)
}
