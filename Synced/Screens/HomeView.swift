import SwiftUI
import Supabase

struct HomeView: View {
    @AppStorage("userName")           private var userName: String = "there"
    @AppStorage("trainingFrequency")  private var trainingFrequency: Int = 4
    @AppStorage("sleepBaseline")      private var sleepBaseline: Double = 7.5

    @State private var profileRow: ProfileRow? = nil
    @State private var todayHasPreLift: Bool = false
    @State private var todayHasPostLift: Bool = false
    @State private var lastSessionRating: Int? = nil

    @State private var preLiftDone: Bool = false
    @State private var postLiftDone: Bool = false
    @State private var showingPreLift: Bool = false
    @State private var showingPostLift: Bool = false
    @State private var showingProfile: Bool = false

    private var currentTier: Tier { tierFromDB(profileRow?.tier) }
    private var currentScore: Int { profileRow?.score ?? 0 }
    private var displayName: String {
        if let name = profileRow?.username, !name.isEmpty { return name }
        return userName
    }

    var body: some View {
        ZStack {
            SYN.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.top, 16)

                    heroCard
                        .padding(.top, 48)

                    Text("Resets Sunday at midnight")
                        .font(.synText(12))
                        .foregroundStyle(SYN.textFaint)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)

                    checkInsSection
                        .padding(.top, 32)

                    quickStatsRow
                        .padding(.top, 32)

                    Color.clear.frame(height: 32)
                }
                .padding(.horizontal, Spacing.pageH)
            }
        }
        .sheet(isPresented: $showingPreLift) {
            PreLiftCheckInView(isComplete: $preLiftDone)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showingPostLift) {
            PostLiftCheckInView(isComplete: $postLiftDone)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .task { await loadFromSupabase() }
        .onChange(of: preLiftDone) { _, new in
            guard new else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                Task { await loadFromSupabase() }
            }
        }
        .onChange(of: postLiftDone) { _, new in
            guard new else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                Task { await loadFromSupabase() }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Good morning,")
                    .font(.synText(14))
                    .foregroundStyle(SYN.textDim)
                Text(displayName)
                    .font(.synDisplay(20, weight: .bold))
                    .foregroundStyle(SYN.text)
            }

            Spacer()

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(SYN.amber)
                    Text("\(profileRow?.streak ?? 0)")
                        .font(.synMono(16, weight: .bold))
                        .foregroundStyle(SYN.text)
                    Text("day streak")
                        .font(.synText(12))
                        .foregroundStyle(SYN.textDim)
                }

                Button(action: { showingProfile = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(SYN.textDim)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Hero score card

    private var heroCard: some View {
        VStack(spacing: 0) {
            EyebrowText(text: "Your Synced score")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 16)

            Text("\(currentScore)")
                .font(.synMono(80, weight: .bold))
                .kerning(-2)
                .foregroundStyle(currentTier.color)
                .shadow(color: currentTier.color.opacity(0.25), radius: 16)
                .contentTransition(.numericText())

            Spacer().frame(height: 8)

            HStack(spacing: 8) {
                Circle()
                    .fill(currentTier.color)
                    .frame(width: 8, height: 8)
                Text(currentTier.displayName)
                    .font(.synDisplay(17, weight: .semibold))
                    .foregroundStyle(currentTier.color)
            }

            Spacer().frame(height: 12)

            if let next = currentTier.next {
                let pointsToNext = max(0, next.range.lowerBound - currentScore)
                Text("\(pointsToNext) points to \(next.displayName)")
                    .font(.synText(13))
                    .foregroundStyle(SYN.textDim)

                Spacer().frame(height: 16)

                tierProgressBar(score: currentScore, tier: currentTier, next: next)
            } else {
                Text("Top tier reached")
                    .font(.synText(13))
                    .foregroundStyle(SYN.textDim)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(SYN.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(SYN.border, lineWidth: 1)
        )
        .shadow(color: SYN.cyan.opacity(0.20), radius: 12)
    }

    private func tierProgressBar(score: Int, tier: Tier, next: Tier) -> some View {
        let span = max(1, next.range.lowerBound - tier.range.lowerBound)
        let progress = Double(score - tier.range.lowerBound) / Double(span)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(SYN.border)
                RoundedRectangle(cornerRadius: 2)
                    .fill(tier.color)
                    .frame(width: geo.size.width * min(1, max(0, progress)))
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 16)
    }

    // MARK: - Check-ins

    private var checkInsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "Today's check-ins")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 16)

            VStack(spacing: 12) {
                CheckInCard(
                    title: "Pre-lift check-in",
                    subtitle: "Sleep, energy, nutrition",
                    state: (todayHasPreLift || preLiftDone) ? .done : .active,
                    onStart: { showingPreLift = true }
                )
                CheckInCard(
                    title: "Post-lift check-in",
                    subtitle: "Session feel, performance",
                    state: postLiftState,
                    onStart: { showingPostLift = true }
                )
            }
        }
    }

    private var postLiftState: CheckInCard.CheckState {
        let preDone = todayHasPreLift || preLiftDone
        if !preDone { return .locked }
        if todayHasPostLift || postLiftDone { return .done }
        return .active
    }

    // MARK: - Quick stats

    private var quickStatsRow: some View {
        HStack(spacing: 8) {
            StatPill(value: String(format: "%.1f", sleepBaseline), label: "hrs sleep")
            StatPill(value: "\(trainingFrequency)",                label: "days/week")
            LastSessionPill(rating: lastSessionRating)
        }
    }

    // MARK: - Supabase

    private func tierFromDB(_ value: String?) -> Tier {
        guard let value, !value.isEmpty else { return .active }
        let lower = value.lowercased()
        for tier in Tier.allCases {
            if tier.rawValue.lowercased() == lower { return tier }
            if tier.displayName.lowercased() == lower { return tier }
        }
        return .active
    }

    private func loadFromSupabase() async {
        guard let userID = supabase.auth.currentSession?.user.id else { return }
        let userIDString = userID.uuidString
        let isoStartOfDay = ISO8601DateFormatter()
            .string(from: Calendar.current.startOfDay(for: Date()))

        async let profileRowsTask: [ProfileRow] = supabase
            .from("profiles")
            .select("username,tier,score,streak")
            .eq("id", value: userIDString)
            .limit(1)
            .execute()
            .value

        async let preRowsTask: [HomeIdRow] = supabase
            .from("pre_lift_checkins")
            .select("id")
            .eq("user_id", value: userIDString)
            .gte("created_at", value: isoStartOfDay)
            .limit(1)
            .execute()
            .value

        async let postRowsTask: [HomeIdRow] = supabase
            .from("post_lift_checkins")
            .select("id")
            .eq("user_id", value: userIDString)
            .gte("created_at", value: isoStartOfDay)
            .limit(1)
            .execute()
            .value

        async let lastRatingTask: [HomeRatingRow] = supabase
            .from("post_lift_checkins")
            .select("session_rating")
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        let profileResult = try? await profileRowsTask
        let preResult = try? await preRowsTask
        let postResult = try? await postRowsTask
        let lastResult = try? await lastRatingTask

        let newProfile = profileResult?.first ?? profileRow
        let newTodayHasPreLift = preResult.map { !$0.isEmpty } ?? todayHasPreLift
        let newTodayHasPostLift = postResult.map { !$0.isEmpty } ?? todayHasPostLift
        let newLastSessionRating = lastResult.map { $0.first?.session_rating } ?? lastSessionRating

        await MainActor.run {
            withAnimation(.easeOut(duration: 0.6)) {
                self.profileRow        = newProfile
                self.todayHasPreLift   = newTodayHasPreLift
                self.todayHasPostLift  = newTodayHasPostLift
                self.lastSessionRating = newLastSessionRating
            }
        }
    }
}

// MARK: - Supabase row models

private struct ProfileRow: Decodable {
    let username: String?
    let tier: String?
    let score: Int?
    let streak: Int?
}

private struct HomeIdRow: Decodable {
    let id: String
}

private struct HomeRatingRow: Decodable {
    let session_rating: Int
}

// MARK: - Check-in card

private struct CheckInCard: View {
    enum CheckState { case active, locked, done }

    let title: String
    let subtitle: String
    let state: CheckState
    var onStart: () -> Void = {}

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.synDisplay(16, weight: .semibold))
                    .foregroundStyle(SYN.text)
                Text(subtitle)
                    .font(.synText(13))
                    .foregroundStyle(SYN.textDim)
            }

            Spacer()

            switch state {
            case .active:
                Button(action: onStart) { startPill(active: true) }
                    .buttonStyle(.plain)
            case .locked:
                startPill(active: false)
            case .done:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(SYN.green)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(SYN.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(SYN.border, lineWidth: 1)
        )
    }

    private func startPill(active: Bool) -> some View {
        let tint = active ? SYN.cyan : SYN.textFaint
        return HStack(spacing: 4) {
            if !active {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tint)
            }
            Text("Start")
                .font(.synText(14, weight: .semibold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(tint, lineWidth: 1.5)
        )
    }
}

// MARK: - Stat pill

private struct LastSessionPill: View {
    let rating: Int?

    var body: some View {
        VStack(spacing: 4) {
            if let rating {
                HStack(spacing: 6) {
                    Circle()
                        .fill(colorForRating(rating))
                        .frame(width: 8, height: 8)
                    Text("\(rating)")
                        .font(.synMono(20, weight: .bold))
                        .foregroundStyle(SYN.text)
                }
            } else {
                Text("--")
                    .font(.synMono(20, weight: .bold))
                    .foregroundStyle(SYN.textFaint)
            }
            Text("last session")
                .font(.synText(11))
                .foregroundStyle(SYN.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SYN.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SYN.border, lineWidth: 1)
        )
    }

    private func colorForRating(_ n: Int) -> Color {
        switch n {
        case 1: return SYN.red
        case 2: return SYN.amber
        case 3: return SYN.text
        case 4: return SYN.green
        default: return SYN.cyan
        }
    }
}

private struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.synMono(20, weight: .bold))
                .foregroundStyle(SYN.text)
            Text(label)
                .font(.synText(11))
                .foregroundStyle(SYN.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
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

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}
