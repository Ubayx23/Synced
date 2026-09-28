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

    // Tap-to-label. MuscleMap reports which muscle was tapped but not where;
    // a separate tap gesture records where. Both fire on the same tap and are
    // paired right after it.
    @State private var label: MuscleLabel?
    @State private var labelSize: CGSize = .zero
    @State private var pendingPoint: CGPoint?
    @State private var pendingMuscle: Muscle?
    @State private var resolveScheduled = false
    private static let screenSpace = "recoveryScreen"
    private static let labelHold: Duration = .seconds(2.5)

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
            // Taps anywhere off the anatomy close the label.
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { dismissLabel() }
            )

            labelOverlay
        }
        .coordinateSpace(name: Self.screenSpace)
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
                EyebrowText(text: "Last workout")
                    .foregroundStyle(SYN.textDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text("\(store.freshCount)")
                    .font(.synMono(48, weight: .bold))
                    .foregroundStyle(SYN.text)
                    .contentTransition(.numericText())
                EyebrowText(text: "Ready to train")
                    .foregroundStyle(SYN.textDim)
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
                .onMuscleSelected { muscle, _ in
                    pendingMuscle = muscle
                    scheduleResolve()
                }
            highlighted(BodyView(gender: gender, side: .front, style: glowStyle)) { $0 == .ready }
                .allowsHitTesting(false)
        }
        // Records where the tap landed; runs alongside MuscleMap's own tap.
        .simultaneousGesture(
            SpatialTapGesture(coordinateSpace: .named(Self.screenSpace))
                .onEnded { value in
                    pendingPoint = value.location
                    scheduleResolve()
                }
        )
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

    // MARK: - Tap label

    /// App group for a tapped MuscleMap muscle. Always-visible sub-groups
    /// report their parent (adductors come back as hamstring), so match on
    /// a mapped muscle's parent too. Head, hands, knees, and feet have none.
    private static func group(for tapped: Muscle) -> MuscleGroup? {
        MuscleGroup.allCases.first { group in
            (muscles[group] ?? []).contains { $0 == tapped || $0.parentGroup == tapped }
        }
    }

    /// Pairs the two halves of one tap on the next run loop turn: a muscle
    /// hit shows its label at the tap point, and a tap with no muscle (empty
    /// space, head, hands, feet) closes the label.
    private func scheduleResolve() {
        guard !resolveScheduled else { return }
        resolveScheduled = true
        DispatchQueue.main.async {
            resolveScheduled = false
            let muscle = pendingMuscle
            let point = pendingPoint
            pendingMuscle = nil
            pendingPoint = nil
            guard let muscle, let group = Self.group(for: muscle), let point else {
                dismissLabel()
                return
            }
            showLabel(for: group, at: point)
        }
    }

    /// Replaces any current label; tapping the same group again restarts the
    /// hold timer.
    private func showLabel(for group: MuscleGroup, at point: CGPoint) {
        let next = MuscleLabel(group: group, point: point)
        withAnimation(.easeOut(duration: 0.15)) { label = next }
        Task {
            try? await Task.sleep(for: Self.labelHold)
            if label?.id == next.id { dismissLabel() }
        }
    }

    private func dismissLabel() {
        guard label != nil else { return }
        withAnimation(.easeOut(duration: 0.15)) { label = nil }
    }

    /// "Trained today", "Trained yesterday", "Trained 3 days ago", or
    /// "Not logged in 14 days".
    private func contextLine(for group: MuscleGroup) -> String {
        switch store.daysSince[group] {
        case nil:    return "Not logged in \(RecoveryStore.windowDays) days"
        case 0:      return "Trained today"
        case 1:      return "Trained yesterday"
        case let n?: return "Trained \(n) days ago"
        }
    }

    /// Bottom center sits 20pt above the tap, kept inside the page margins,
    /// and flips below the tap when it would run off the top.
    private var labelOverlay: some View {
        GeometryReader { proxy in
            if let label {
                let gap: CGFloat = 20
                let halfW = labelSize.width / 2
                let halfH = labelSize.height / 2
                let minX = Spacing.pageH + halfW
                let maxX = proxy.size.width - Spacing.pageH - halfW
                let x = min(max(label.point.x, minX), max(minX, maxX))
                let above = label.point.y - gap - halfH
                let y = above - halfH < 0 ? label.point.y + gap + halfH : above

                VStack(spacing: 2) {
                    Text(label.group.title)
                        .font(.synText(15, weight: .semibold))
                        .foregroundStyle(SYN.text)
                    Text(contextLine(for: label.group))
                        .font(.synText(12))
                        .foregroundStyle(SYN.textDim)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .fill(SYN.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .stroke(SYN.border, lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 8, y: 2)
                .fixedSize()
                .onGeometryChange(for: CGSize.self) { $0.size } action: { labelSize = $0 }
                .position(x: x, y: y)
                // Taps on the label itself do not dismiss it.
                .onTapGesture {}
                .id(label.id)
                .transition(.opacity.combined(with: .offset(y: 4)))
                .accessibilityElement(children: .combine)
            }
        }
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

/// One visible tap label; a new id replaces the old one rather than stacking.
private struct MuscleLabel: Equatable {
    let id = UUID()
    let group: MuscleGroup
    let point: CGPoint
}
