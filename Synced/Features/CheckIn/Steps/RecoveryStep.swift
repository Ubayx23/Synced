import SwiftUI

struct RecoveryStep: View {
    @Binding var muscleGroups: [String]
    @Binding var lastTrainedGap: String

    private struct MuscleTile {
        let label: String
        let icon: String
    }

    private static let gridTiles: [MuscleTile] = [
        .init(label: "Chest",     icon: "figure.strengthtraining.traditional"),
        .init(label: "Back",      icon: "figure.rowing"),
        .init(label: "Shoulders", icon: "figure.arms.open"),
        .init(label: "Arms",      icon: "dumbbell.fill"),
        .init(label: "Legs",      icon: "figure.run"),
        .init(label: "Full body", icon: "bolt.fill"),
    ]

    private static let cardioTile = MuscleTile(label: "Cardio only", icon: "heart.fill")

    private struct GapOption: Identifiable {
        let label: String
        let subtitle: String
        let icon: String
        let iconColor: Color
        var id: String { label }
    }

    private static let gapOptions: [GapOption] = [
        .init(label: "Today",            subtitle: "Same day, less recovery",      icon: "clock.badge.exclamationmark.fill", iconColor: SYN.red),
        .init(label: "Yesterday",        subtitle: "24 hours since last session",  icon: "moon.fill",                          iconColor: SYN.amber),
        .init(label: "2 days ago",       subtitle: "Getting close to optimal",     icon: "calendar",                           iconColor: SYN.cyan),
        .init(label: "3 or more days",   subtitle: "Fully recovered",              icon: "checkmark.seal.fill",                iconColor: SYN.green),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowText(text: "Step 1 of 4")
                    .foregroundStyle(SYN.textFaint)

                Spacer().frame(height: 24)

                Text("What are you training today?")
                    .font(.synDisplay(28, weight: .bold))
                    .foregroundStyle(SYN.text)

                Spacer().frame(height: 8)

                Text("Select all that apply.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)

                Spacer().frame(height: 24)

                muscleGrid

                if !muscleGroups.isEmpty {
                    Spacer().frame(height: 32)
                    divider
                    Spacer().frame(height: 24)
                    lastTrainedSection
                        .transition(
                            .opacity.combined(with: .move(edge: .top))
                        )
                }

                Color.clear.frame(height: 32)
            }
            .padding(.horizontal, Spacing.pageH)
            .animation(.easeInOut(duration: 0.3), value: muscleGroups.isEmpty)
        }
    }

    // MARK: - Muscle grid

    private var muscleGrid: some View {
        let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return VStack(spacing: 12) {
            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(Self.gridTiles, id: \.label) { tile in
                    muscleTileView(tile)
                }
            }
            muscleTileView(Self.cardioTile)
        }
    }

    @ViewBuilder
    private func muscleTileView(_ tile: MuscleTile) -> some View {
        let isSelected = muscleGroups.contains(tile.label)
        Button(action: { toggle(tile.label) }) {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 10) {
                    Image(systemName: tile.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? SYN.cyan : SYN.textDim)
                    Text(tile.label)
                        .font(.synDisplay(15, weight: .semibold))
                        .foregroundStyle(SYN.text)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(SYN.cyan)
                        .padding(8)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? SYN.surfaceHi : SYN.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? SYN.cyan : SYN.border,
                            lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: isSelected ? SYN.cyan.opacity(0.20) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ label: String) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            let cardio = Self.cardioTile.label
            if label == cardio {
                if muscleGroups.contains(cardio) {
                    muscleGroups.removeAll { $0 == cardio }
                } else {
                    muscleGroups = [cardio]
                }
            } else {
                muscleGroups.removeAll { $0 == cardio }
                if let idx = muscleGroups.firstIndex(of: label) {
                    muscleGroups.remove(at: idx)
                } else {
                    muscleGroups.append(label)
                }
            }
        }
    }

    // MARK: - Last trained

    private var lastTrainedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(headlineForSelection)
                .font(.synDisplay(20, weight: .semibold))
                .foregroundStyle(SYN.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 8)

            Text("We track your recovery window per muscle group.")
                .font(.synText(13))
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 20)

            VStack(spacing: 10) {
                ForEach(Self.gapOptions) { opt in
                    gapOptionCard(opt)
                }
            }
        }
    }

    private var headlineForSelection: String {
        switch muscleGroups.count {
        case 0:  return ""
        case 1:  return "When did you last train \(name(for: muscleGroups[0]))?"
        case 2:  return "When did you last train \(name(for: muscleGroups[0])) and \(name(for: muscleGroups[1]))?"
        default: return "When did you last train these muscles?"
        }
    }

    private func name(for label: String) -> String {
        switch label {
        case "Cardio only": return "cardio"
        case "Full body":   return "your full body"
        default:            return label.lowercased()
        }
    }

    @ViewBuilder
    private func gapOptionCard(_ opt: GapOption) -> some View {
        let isSelected = lastTrainedGap == opt.label
        Button(action: {
            withAnimation(.spring(response: 0.3)) { lastTrainedGap = opt.label }
        }) {
            HStack(spacing: 16) {
                Image(systemName: opt.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(opt.iconColor)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(opt.label)
                        .font(.synDisplay(16, weight: .semibold))
                        .foregroundStyle(SYN.text)
                    Text(opt.subtitle)
                        .font(.synText(13))
                        .foregroundStyle(SYN.textFaint)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? SYN.surfaceHi : SYN.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? SYN.cyan : SYN.border,
                            lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: isSelected ? SYN.cyan.opacity(0.25) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(SYN.border)
            .frame(height: 1)
            .padding(.horizontal, 24)
    }
}
