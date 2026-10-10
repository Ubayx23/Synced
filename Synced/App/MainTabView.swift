import SwiftUI
import UIKit

/// Signed-in root: Today and Progress. Each tab owns its own header with
/// the profile icon, so Profile opens from either. Week planning lives in
/// Today's day strip, and Recovery opens as a sheet from Today.
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

    private enum Tab { case today, progress }

    @State private var tab: Tab = .today
    @State private var router = AppRouter.shared

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "smallcircle.filled.circle") }
                .tag(Tab.today)

            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.bar") }
                .tag(Tab.progress)
        }
        .tint(SYN.cyan)
        // A tapped reminder lands on Today, which opens the Log sheet.
        .onChange(of: router.pendingLogFromReminder) { _, pending in
            if pending { tab = .today }
        }
    }
}
