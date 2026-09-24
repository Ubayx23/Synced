import SwiftUI
import UIKit

/// Signed-in root: Week and Progress. Each tab owns its own header with the
/// profile icon, so Profile opens from either.
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

    var body: some View {
        TabView {
            WeekView()
                .tabItem { Label("Week", systemImage: "calendar") }

            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .tint(SYN.cyan)
    }
}
