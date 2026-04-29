import SwiftUI

struct SessionDetailsStep: View {
    @Binding var sessionDuration: String
    @Binding var sessionNotes: String

    @FocusState private var notesFocused: Bool

    private struct DurationTile: Identifiable {
        let label: String
        let icon: String
        let iconColor: Color
        var id: String { label }
    }

    private static let durationTiles: [DurationTile] = [
        .init(label: "Under 45m", icon: "hare.fill",                            iconColor: SYN.amber),
        .init(label: "45 to 60m", icon: "figure.strengthtraining.traditional",  iconColor: SYN.text),
        .init(label: "60 to 90m", icon: "flame.fill",                           iconColor: SYN.cyan),
        .init(label: "90m+",      icon: "trophy.fill",                          iconColor: SYN.green),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowText(text: "Step 2 of 2")
                    .foregroundStyle(SYN.textFaint)

                Spacer().frame(height: 24)

                Text("Last details.")
                    .font(.synDisplay(28, weight: .bold))
                    .foregroundStyle(SYN.text)

                Spacer().frame(height: 8)

                Text("How long and any notes.")
                    .font(.synText(15))
                    .foregroundStyle(SYN.textDim)

                Spacer().frame(height: 32)

                EyebrowText(text: "How long did you lift?")
                    .foregroundStyle(SYN.textFaint)

                Spacer().frame(height: 12)

                durationGrid

                Spacer().frame(height: 32)

                divider

                Spacer().frame(height: 24)

                EyebrowText(text: "Anything to note?")
                    .foregroundStyle(SYN.textFaint)

                Spacer().frame(height: 4)

                Text("Optional. PRs, how you felt, anything.")
                    .font(.synText(13))
                    .foregroundStyle(SYN.textFaint)

                Spacer().frame(height: 16)

                notesField

                Spacer().frame(height: 12)

                charCountRow

                Color.clear.frame(height: 32)
            }
            .padding(.horizontal, Spacing.pageH)
        }
    }

    // MARK: - Duration grid

    private var durationGrid: some View {
        let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: cols, spacing: 12) {
            ForEach(Self.durationTiles) { tile in
                durationTileView(tile)
            }
        }
    }

    @ViewBuilder
    private func durationTileView(_ tile: DurationTile) -> some View {
        let isSelected = sessionDuration == tile.label
        Button {
            withAnimation(.spring(response: 0.25)) {
                sessionDuration = tile.label
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: tile.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(tile.iconColor)
                Text(tile.label)
                    .font(.synText(14, weight: .semibold))
                    .foregroundStyle(SYN.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? SYN.surfaceHi : SYN.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? SYN.cyan : SYN.border,
                            lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: isSelected ? SYN.cyan.opacity(0.20) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notes

    private var notesField: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(SYN.surface)

            // Border layer animates color independently so the
            // TextEditor's text changes don't inherit the animation.
            RoundedRectangle(cornerRadius: 14)
                .stroke(notesFocused ? SYN.cyan : SYN.border,
                        lineWidth: notesFocused ? 1.5 : 1)
                .animation(.easeInOut(duration: 0.2), value: notesFocused)

            if sessionNotes.isEmpty && !notesFocused {
                Text("e.g. Hit a new bench PR. Left knee felt off.")
                    .font(.system(size: 15))
                    .foregroundColor(SYN.textFaint)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $sessionNotes)
                .font(.system(size: 15))
                .foregroundColor(SYN.text)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .focused($notesFocused)
                .frame(minHeight: 100, maxHeight: 160)
                .transaction { $0.animation = nil }
        }
        .frame(minHeight: 100, maxHeight: 160)
        .contentShape(Rectangle())
        .onTapGesture { notesFocused = true }
    }

    @ViewBuilder
    private var charCountRow: some View {
        HStack {
            Spacer()
            if sessionNotes.count > 50 {
                Text("\(sessionNotes.count) chars")
                    .font(.synText(11))
                    .foregroundStyle(SYN.textFaint)
            }
        }
        .frame(height: 14)
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(SYN.border)
            .frame(height: 1)
            .padding(.horizontal, 24)
    }
}
