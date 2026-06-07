import SwiftUI
import Supabase

private struct LeaderRow: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let username: String
    let score: Int
    let tier: String
    let tierColor: String
    let isCurrentUser: Bool
}

private struct LeaderboardRowDB: Decodable {
    let user_id: String
    let display_name: String?
    let tier: String?
    let score: Int?
    let streak: Int?
}

struct LeaderboardView: View {
    @State private var entries: [LeaderRow] = []

    var body: some View {
        ZStack {
            SYN.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 16)

                    Spacer().frame(height: 8)

                    Text("Global rankings this week")
                        .font(.synText(14))
                        .foregroundStyle(SYN.textDim)

                    Spacer().frame(height: 4)

                    Text("Resets Sunday at midnight")
                        .font(.synText(12))
                        .foregroundStyle(SYN.textFaint)

                    if entries.isEmpty {
                        emptyState
                            .padding(.top, 80)
                    } else {
                        Spacer().frame(height: 24)
                        LazyVStack(spacing: 8) {
                            ForEach(entries) { entry in
                                LeaderboardRow(friend: entry)
                            }
                        }
                    }

                    Color.clear.frame(height: 32)
                }
                .padding(.horizontal, Spacing.pageH)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .task { await loadEntries() }
    }

    // MARK: - Supabase

    private func loadEntries() async {
        guard let currentUserID = supabase.auth.currentSession?.user.id else { return }

        do {
            let rows: [LeaderboardRowDB] = try await supabase
                .from("leaderboard_entries")
                .select("user_id, display_name, tier, score, streak")
                .order("score", ascending: false)
                .execute()
                .value

            let mapped: [LeaderRow] = rows.enumerated().map { idx, row in
                let name = row.display_name ?? "User"
                let handle = "@" + name.lowercased().filter { !$0.isWhitespace }
                return LeaderRow(
                    rank: idx + 1,
                    name: name,
                    username: handle,
                    score: row.score ?? 0,
                    tier: row.tier ?? "Active",
                    tierColor: tierColorHex(row.tier),
                    isCurrentUser: row.user_id == currentUserID.uuidString
                )
            }

            await MainActor.run { entries = mapped }
        } catch {
            // swallow silently
        }
    }

    private func tierColorHex(_ value: String?) -> String {
        switch value?.lowercased() {
        case "cooked":              return "5A5A60"
        case "active":              return "FFFFFF"
        case "dialed":              return "22C55E"
        case "lockedin", "locked in": return "00E5FF"
        case "synced":              return "00E5FF"
        default:                    return "FFFFFF"
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Leaderboard")
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 40))
                .foregroundStyle(SYN.border)
            Spacer().frame(height: 16)
            Text("No sessions yet")
                .font(.synDisplay(17, weight: .semibold))
                .foregroundStyle(SYN.text)
            Spacer().frame(height: 8)
            Text("Complete a check-in to appear on the global leaderboard")
                .font(.synText(14))
                .foregroundStyle(SYN.textDim)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct LeaderboardRow: View {
    let friend: LeaderRow

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 4) {
                if friend.rank == 1 {
                    GlowDot(color: SYN.amber, diameter: 8)
                }
                Text("\(friend.rank)")
                    .font(.synMono(18, weight: .bold))
                    .foregroundStyle(rankColor)
            }
            .frame(width: 32, alignment: .leading)

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
