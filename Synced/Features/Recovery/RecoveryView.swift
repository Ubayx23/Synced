import MuscleMap
import SwiftUI

/// Recovery tab: a front anatomy view where ready muscles glow cyan and
/// recently worked ones turn gray. Read-only.
struct RecoveryView: View {
    @State private var store = RecoveryStore()
    @State private var showingProfile = false
    @Environment(\.scenePhase) private var scenePhase
    /// Chosen at sign up; picks the male or female body model.
    @AppStorage(BodyModel.storageKey) private var bodyModel = BodyModel.male.rawValue

    private var gender: BodyGender {
        BodyGender(rawValue: bodyModel) ?? .male
    }

    /// App groups to MuscleMap muscles on the front view. Back is only
    /// visible from the front as the trapezius.
    private static let muscles: [MuscleGroup: [Muscle]] = [
        .chest:     [.chest],
        .shoulders: [.deltoids],
        .back:      [.trapezius],
        .arms:      [.biceps, .triceps, .forearm],
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

                stats

                // Takes all remaining height; MuscleMap scales the body to fit.
                anatomy
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, Spacing.s)

                // Only before the first logged session in the window: frames
                // the all-ready body as a starting point.
                if store.loaded && !store.hasSessions {
                    Text("Log a session to see your recovery come to life.")
                        .font(.synText(13))
                        .foregroundStyle(SYN.textDim)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, Spacing.md)
                }

                // Not a scroll view, so the tab bar's safe area already
                // clears it; no extra tab bar clearance needed.
                legend
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, Spacing.md)
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
                Text(daysSinceText)
                    .font(.synMono(48, weight: .bold))
                    .foregroundStyle(SYN.text)
                    // "Yesterday" is wider than half the row at 48pt; shrink
                    // it rather than wrap or crowd the right stat.
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
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

    /// "Today" and "Yesterday" read better than 0 and 1.
    private var daysSinceText: String {
        switch store.daysSinceLastWorkout {
        case nil:     return "-"
        case 0:       return "Today"
        case 1:       return "Yesterday"
        case let n?:  return "\(n) days"
        }
    }

    // MARK: - Anatomy

    /// Two stacked copies of the same front body. The base shows every
    /// group's state; the top copy draws only ready groups with a cyan
    /// shadow, because MuscleMap's shadow applies to all highlighted muscles
    /// at once and the glow belongs on ready ones only.
    private var anatomy: some View {
        ZStack {
            // Ready groups are left to the glow layer so their color is drawn
            // once; drawing them on both layers doubles the opacity and undoes
            // the softened ready tone.
            highlighted(BodyView(gender: gender, side: .front, style: baseStyle)) { $0 != .ready }
            highlighted(BodyView(gender: gender, side: .front, style: glowStyle)) { $0 == .ready }
                .allowsHitTesting(false)
        }
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

    /// Non-muscle parts stay dark with a faint outline so the silhouette
    /// reads; every mapped group is colored by its state.
    private var baseStyle: BodyViewStyle {
        BodyViewStyle(
            defaultFillColor: SYN.muscleBase,
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
        let worked = MuscleGroup.allCases.filter { store.state(for: $0) == .worked }.map(\.title)
        let recovering = MuscleGroup.allCases.filter { store.state(for: $0) == .recovering }.map(\.title)
        var parts: [String] = []
        if !worked.isEmpty { parts.append("Worked: \(worked.joined(separator: ", "))") }
        if !recovering.isEmpty { parts.append("Recovering: \(recovering.joined(separator: ", "))") }
        parts.append("\(store.freshCount) groups ready")
        return parts.joined(separator: ". ")
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: Spacing.lg) {
            legendItem(RecoveryState.ready.color, "Ready")
            legendItem(RecoveryState.recovering.color, "Recovering")
            legendItem(RecoveryState.worked.color, "Worked")
        }
    }

    private func legendItem(_ color: Color, _ label: String) -> some View {
        HStack(spacing: Spacing.s) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                // Keeps the dimmer dots legible against the background.
                .overlay(Circle().stroke(SYN.border, lineWidth: 0.5))
            EyebrowText(text: label)
                .foregroundStyle(SYN.textFaint)
        }
    }
}
