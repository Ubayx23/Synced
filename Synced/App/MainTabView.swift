import SwiftUI
import UIKit

/// Signed-in root: Week, Recovery, and Progress. Each tab owns its own
/// header with the profile icon, so Profile opens from any of them.
struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(SYN.bg)
        appearance.shadowColor = UIColor(SYN.border)
        // Strip the iOS 18+ selection pill so only icon and label colors change.
        appearance.selectionIndicatorTintColor = .clear
        appearance.selectionIndicatorImage = UIImage()

        let labelFont = UIFont(name: "Geist-Medium", size: 10) ?? .systemFont(ofSize: 10, weight: .medium)
        let normal: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(SYN.textFaint),
            .font: labelFont,
        ]
        let selected: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(SYN.cyan),
            .font: labelFont,
        ]
        for item in [
            appearance.stackedLayoutAppearance,
            appearance.inlineLayoutAppearance,
            appearance.compactInlineLayoutAppearance,
        ] {
            item.normal.iconColor = UIColor(SYN.textFaint)
            item.selected.iconColor = UIColor(SYN.cyan)
            item.normal.titleTextAttributes = normal
            item.selected.titleTextAttributes = selected
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private enum Tab { case week, recovery, progress }

    @State private var tab: Tab = .week
    @State private var router = AppRouter.shared

    var body: some View {
        TabView(selection: $tab) {
            WeekView()
                .tabItem { Label("Week", systemImage: "calendar") }
                .tag(Tab.week)

            // Middle, next to planning, so recovery informs the week.
            RecoveryView()
                .tabItem { Label("Recovery", systemImage: "figure.arms.open") }
                .tag(Tab.recovery)

            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tab.progress)
        }
        .tint(SYN.cyan)
        // A tapped reminder lands on Week, which opens the Log sheet.
        .onChange(of: router.pendingLogFromReminder) { _, pending in
            if pending { tab = .week }
        }
    }
}
