import SwiftUI

public struct GamesView: View {
    @ObservedObject var catalog = CatalogService.shared
    @ObservedObject var theme = ThemeConfig.shared

    public init() {}

    private var games: [AppItem] {
        let onlyGames = catalog.apps.filter { $0.category == "games" }
        return onlyGames.isEmpty ? catalog.apps : onlyGames
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.canvasBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Игры (\(games.count))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)

                        LazyVStack(spacing: 12) {
                            ForEach(games) { game in
                                NavigationLink(destination: ProductDetailView(app: game)) {
                                    AppCardRow(app: game)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 12)
                }
                .refreshable {
                    catalog.loadCatalog()
                }
            }
            .navigationTitle("Игры")
        }
    }
}
