import SwiftUI

public struct RootTabView: View {
    @ObservedObject var theme = ThemeConfig.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showOnboarding: Bool = false

    public init() {}

    public var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Сегодня", systemImage: "doc.text.image")
                }

            GamesView()
                .tabItem {
                    Label("Игры", systemImage: "gamecontroller.fill")
                }

            AppsView()
                .tabItem {
                    Label("Приложения", systemImage: "square.stack.3d.up.fill")
                }

            SearchView()
                .tabItem {
                    Label("Поиск", systemImage: "magnifyingglass")
                }
        }
        .tint(theme.rosePrimary)
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(
                isPresented: $showOnboarding,
                onImportCertificate: {
                    hasCompletedOnboarding = true
                    showOnboarding = false
                },
                onExploreCatalog: {
                    hasCompletedOnboarding = true
                    showOnboarding = false
                }
            )
        }
    }
}
