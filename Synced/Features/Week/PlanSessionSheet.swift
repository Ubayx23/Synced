import SwiftUI

/// Half-height sheet for planning one session on a given day. Picking a type
/// saves immediately and dismisses; a failed save keeps the sheet open.
struct PlanSessionSheet: View {
    let day: Date
    let store: WeekStore

    @Environment(\.dismiss) private var dismiss
    @State private var saving: SessionType?
    @State private var errorMessage: String?

    private let subtitles: [SessionType: String] = [
        .climb: "Bouldering, routes, or board",
        .lift:  "Supporting strength work",
        .rest:  "Recovery day, no training",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Plan for \(day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))")
                .font(.synDisplay(22, weight: .bold))
                .foregroundStyle(SYN.text)
                .kerning(-0.4)

            Spacer().frame(height: Spacing.lg)

            VStack(spacing: Spacing.m) {
                ForEach(SessionType.allCases) { type in
                    SelectableCard(
                        title: type.title,
                        subtitle: subtitles[type],
                        leading: AnyView(icon(for: type)),
                        height: 72,
                        selected: saving == type
                    ) {
                        save(type)
                    }
                    .opacity(saving == nil || saving == type ? 1 : 0.4)
                }
            }
            .disabled(saving != nil)

            if let errorMessage {
                Spacer().frame(height: Spacing.m)
                Text(errorMessage)
                    .font(.synText(13))
                    .foregroundStyle(SYN.red)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.pageH)
        .padding(.top, Spacing.xl)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(SYN.bg)
        .presentationCornerRadius(Radius.card * 2)
    }

    private func icon(for type: SessionType) -> some View {
        Image(systemName: type.symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(type.color)
            .frame(width: 40, height: 40)
            .background(Circle().fill(type.color.opacity(0.1)))
            .overlay(Circle().stroke(type.color.opacity(0.5), lineWidth: 1))
    }

    private func save(_ type: SessionType) {
        guard saving == nil else { return }
        saving = type
        errorMessage = nil
        Task {
            do {
                try await store.plan(type, on: day)
                dismiss()
            } catch {
                saving = nil
                errorMessage = "Couldn't save that session. \(error.localizedDescription)"
            }
        }
    }
}
