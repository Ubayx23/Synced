import SwiftUI
import UIKit

struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(SYN.bg)
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        appearance.backgroundImage = UIImage()
        // Strip the iOS 18+ pill/glass selection background so only the icon/label colors change.
        appearance.selectionIndicatorTintColor = .clear
        appearance.selectionIndicatorImage = UIImage()

        let labelFont = UIFont.systemFont(ofSize: 10, weight: .medium)
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
        UITabBar.appearance().tintColor = UIColor(SYN.cyan)
        UITabBar.appearance().unselectedItemTintColor = UIColor(SYN.textFaint)
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            LeaderboardView()
                .tabItem { Label("Leaderboard", systemImage: "trophy.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(SYN.cyan)
        .preferredColorScheme(.dark)
    }
}
