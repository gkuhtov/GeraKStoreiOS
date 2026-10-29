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

                        if catalog.isLoading && catalog.apps.isEmpty {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(.pink)
                                Text("Загрузка игр...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if games.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "gamecontroller")
                                    .font(.system(size: 36))
                                    .foregroundColor(.secondary)
                                Text("Игры не найдены")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(catalog.lastStatus)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Button("Повторить запрос") {
                                    catalog.loadCatalog()
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.pink)
                                .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else {
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
                    }
                    .padding(.top, 12)
                }
                .refreshable {
                    catalog.loadCatalog()
                }
                .onAppear {
                    if catalog.apps.isEmpty {
                        catalog.loadCatalog()
                    }
                }
            }
            .navigationTitle("Игры")
        }
    }
}
