import SwiftUI

// Mock data — Supabase wiring lands on a future branch.
private let mockUserName    = "Ubay"
private let mockTier: Tier  = .dialed
private let mockStreak      = 5
private let mockSleepHours  = 7.5
private let mockDaysPerWeek = 4

struct HomeView: View {
    @State private var displayScore: Int = 67
    @State private var preLiftDone: Bool = false
    @State private var postLiftDone: Bool = false
    @State private var showingPreLift: Bool = false

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
        .onChange(of: preLiftDone) { _, new in
            guard new else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    displayScore = 71
                }
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
                Text(mockUserName)
                    .font(.synDisplay(20, weight: .bold))
                    .foregroundStyle(SYN.text)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(SYN.amber)
                Text("\(mockStreak)")
                    .font(.synMono(16, weight: .bold))
                    .foregroundStyle(SYN.text)
                Text("day streak")
                    .font(.synText(12))
                    .foregroundStyle(SYN.textDim)
            }
        }
    }

    // MARK: - Hero score card

    private var heroCard: some View {
        VStack(spacing: 0) {
            EyebrowText(text: "Your Synced score")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 16)

            Text("\(displayScore)")
                .font(.synMono(80, weight: .bold))
                .kerning(-2)
                .foregroundStyle(mockTier.color)
                .shadow(color: mockTier.color.opacity(0.25), radius: 16)
                .contentTransition(.numericText())

            Spacer().frame(height: 8)

            HStack(spacing: 8) {
                Circle()
                    .fill(mockTier.color)
                    .frame(width: 8, height: 8)
                Text(mockTier.displayName)
                    .font(.synDisplay(17, weight: .semibold))
                    .foregroundStyle(mockTier.color)
            }

            Spacer().frame(height: 12)

            if let next = mockTier.next {
                let pointsToNext = max(0, next.range.lowerBound - displayScore)
                Text("\(pointsToNext) points to \(next.displayName)")
                    .font(.synText(13))
                    .foregroundStyle(SYN.textDim)

                Spacer().frame(height: 16)

                tierProgressBar(score: displayScore, tier: mockTier, next: next)
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
                    state: preLiftDone ? .done : .active,
                    onStart: { showingPreLift = true }
                )
                CheckInCard(
                    title: "Post-lift check-in",
                    subtitle: "Session feel, performance",
                    state: postLiftState,
                    onStart: { /* future: post-lift sheet */ }
                )
            }
        }
    }

    private var postLiftState: CheckInCard.CheckState {
        if postLiftDone { return .done }
        if !preLiftDone { return .locked }
        return .active
    }

    // MARK: - Quick stats

    private var quickStatsRow: some View {
        HStack(spacing: 8) {
            StatPill(value: String(format: "%.1f", mockSleepHours), label: "hrs sleep")
            StatPill(value: "\(mockDaysPerWeek)",                   label: "days/week")
            StatPill(value: "\(mockStreak)",                        label: "day streak")
        }
    }
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
