import MuscleMap
import SwiftUI

/// Recovery tab: a front anatomy view where recently trained muscles glow
/// cyan and rested ones sink into the dark body. Read-only.
struct RecoveryView: View {
    @State private var store = RecoveryStore()
    @State private var showingProfile = false
    @Environment(\.scenePhase) private var scenePhase

    /// App groups to MuscleMap muscles on the front view. Back is only
    /// visible from the front as the trapezius.
    private static let muscles: [MuscleGroup: [Muscle]] = [
        .chest:     [.chest],
        .shoulders: [.deltoids],
        .back:      [.trapezius],
        .biceps:    [.biceps],
        .triceps:   [.triceps],
        .forearms:  [.forearm],
        .core:      [.abs, .obliques],
        .legs:      [.quadriceps, .adductors, .calves, .tibialis],
    ]

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.lg)

                if store.loaded && !store.hasSessions {
                    Text("No sessions logged yet. Log one to see recovery.")
                        .font(.synText(14))
                        .foregroundStyle(SYN.textDim)
                        .frame(maxWidth: .infinity)
                } else {
                    stats
                }

                anatomy
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, Spacing.lg)

                legend
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, Spacing.tabBarClearance)
            }
            .padding(.horizontal, Spacing.pageH)
        }
        .onAppear { Task { await store.load() } }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await store.load() } }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileSheet()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            EyebrowText(text: "Recovery")
                .foregroundStyle(SYN.textFaint)

            Spacer()

            // Same placement and hit target as the other tabs' icon.
            Button { showingProfile = true } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(SYN.textDim)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, -Spacing.m)
            .padding(.trailing, -Spacing.m + 2)
            .accessibilityLabel("Profile")
        }
    }

    // MARK: - Stats

    private var stats: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(store.daysSinceLastWorkout.map(String.init) ?? "-")
                    .font(.synMono(48, weight: .bold))
                    .foregroundStyle(SYN.text)
                    .contentTransition(.numericText())
                EyebrowText(text: "Days since your last workout")
                    .foregroundStyle(SYN.textDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text("\(store.freshCount)")
                    .font(.synMono(48, weight: .bold))
                    .foregroundStyle(SYN.text)
                    .contentTransition(.numericText())
                EyebrowText(text: "Fresh muscle groups")
                    .foregroundStyle(SYN.textDim)
                    .multilineTextAlignment(.trailing)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - Anatomy

    /// Two stacked copies of the same front body. The base shows every
    /// group's state; the top copy draws only fatigued groups with a cyan
    /// shadow, because MuscleMap's shadow applies to all highlighted muscles
    /// at once and the glow belongs on fatigued ones only.
    private var anatomy: some View {
        ZStack {
            highlighted(BodyView(gender: .male, side: .front, style: baseStyle)) { $0 != .fresh }
            highlighted(BodyView(gender: .male, side: .front, style: glowStyle)) { $0 == .fatigued }
                .allowsHitTesting(false)
        }
        .aspectRatio(0.5, contentMode: .fit)
        .animation(.easeOut(duration: 0.3), value: store.daysSince)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private func highlighted(_ base: BodyView, when include: (RecoveryState) -> Bool) -> BodyView {
        var view = base
        for group in MuscleGroup.allCases {
            let state = store.state(for: group)
            guard include(state), let muscles = Self.muscles[group] else { continue }
            view = view.highlight(muscles, color: state.color)
        }
        return view
    }

    /// Rested body: dark fill with a faint outline so the silhouette reads.
    private var baseStyle: BodyViewStyle {
        BodyViewStyle(
            defaultFillColor: SYN.muscleFresh,
            strokeColor: SYN.border,
            strokeWidth: 0.5,
            headColor: SYN.surface,
            hairColor: SYN.surfaceHi
        )
    }

    /// Glow layer: everything clear except highlighted muscles, which get a
    /// soft cyan shadow.
    private var glowStyle: BodyViewStyle {
        BodyViewStyle(
            defaultFillColor: .clear,
            headColor: .clear,
            hairColor: .clear,
            shadowColor: SYN.cyan.opacity(0.5),
            shadowRadius: 8
        )
    }

    private var accessibilitySummary: String {
        let fatigued = MuscleGroup.allCases.filter { store.state(for: $0) == .fatigued }.map(\.title)
        let moderate = MuscleGroup.allCases.filter { store.state(for: $0) == .moderate }.map(\.title)
        var parts: [String] = []
        if !fatigued.isEmpty { parts.append("Fatigued: \(fatigued.joined(separator: ", "))") }
        if !moderate.isEmpty { parts.append("Moderate: \(moderate.joined(separator: ", "))") }
        parts.append("\(store.freshCount) groups recovered")
        return parts.joined(separator: ". ")
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: Spacing.lg) {
            legendItem(RecoveryState.fresh.color, "Recovered")
            legendItem(RecoveryState.moderate.color, "Moderate")
            legendItem(RecoveryState.fatigued.color, "Fatigued")
        }
    }

    private func legendItem(_ color: Color, _ label: String) -> some View {
        HStack(spacing: Spacing.s) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                // The recovered dot is nearly the background color.
                .overlay(Circle().stroke(SYN.border, lineWidth: 0.5))
            EyebrowText(text: label)
                .foregroundStyle(SYN.textFaint)
        }
    }
}
