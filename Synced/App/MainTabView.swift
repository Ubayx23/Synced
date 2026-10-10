import SwiftUI

/// Signed-in root: Today and Progress. TabView keeps each tab's state; its
/// native bar is hidden and SyncedTabBar draws the designed one. Each tab
/// owns its own header with the profile entry, so Profile opens from
/// either. Week planning lives in Today's day strip, and Recovery opens as
/// a sheet from Today.
struct MainTabView: View {
    enum Tab { case today, progress }

    @State private var tab: Tab = .today
    @State private var router = AppRouter.shared

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .withSyncedTabBar($tab)
                .tag(Tab.today)

            ProgressScreen()
                .withSyncedTabBar($tab)
                .tag(Tab.progress)
        }
        // A tapped reminder lands on Today, which opens the Log sheet.
        .onChange(of: router.pendingLogFromReminder) { _, pending in
            if pending { tab = .today }
        }
    }
}

private extension View {
    func withSyncedTabBar(_ selection: Binding<MainTabView.Tab>) -> some View {
        self
            .toolbar(.hidden, for: .tabBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                SyncedTabBar(selection: selection)
            }
    }
}

/// 85pt on a home indicator phone: 51 of bar plus the 34pt indicator area,
/// which the fill extends into. Two equal columns inside 66pt side padding,
/// so the tab centers sit near the left and right thirds.
private struct SyncedTabBar: View {
    @Binding var selection: MainTabView.Tab

    var body: some View {
        HStack(spacing: 0) {
            item(.today, title: "Today", glyph: .today)
            item(.progress, title: "Progress", glyph: .progress)
        }
        .padding(.horizontal, 66)
        .padding(.top, Spacing.s)
        .frame(maxWidth: .infinity)
        .frame(height: 51, alignment: .top)
        .background(SYN.tabBar.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(SYN.border)
                .frame(height: 0.5)
        }
    }

    private func item(_ tab: MainTabView.Tab, title: String, glyph: LineGlyph.Kind) -> some View {
        let isSelected = selection == tab
        return Button { selection = tab } label: {
            VStack(spacing: Spacing.xs) {
                LineGlyph(kind: glyph)
                Text(title)
                    .font(.synText(10, weight: .medium))
            }
            .foregroundStyle(isSelected ? SYN.cyan : SYN.textDim)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
