import SwiftUI

public struct GamesView: View {
    @ObservedObject var theme = ThemeConfig.shared
    @ObservedObject var catalog = CatalogService.shared
    @State private var selectedGenre = "Все"
    private let genres = ["Все", "Экшен", "Гонки", "Стратегии", "РПГ", "Симуляторы", "Квесты"]

    public init() {}

    private var filteredGames: [AppItem] {
        let games = catalog.allApps.filter { $0.category == "games" }
        if selectedGenre == "Все" {
            return games
        }
        return games.filter { $0.subcategory == selectedGenre }
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(genres, id: \.self) { genre in
                                Button(action: {
                                    HapticManager.shared.tap()
                                    selectedGenre = genre
                                }) {
                                    Text(genre)
                                        .font(.system(size: 14, weight: selectedGenre == genre ? .bold : .medium))
                                        .foregroundColor(selectedGenre == genre ? .white : .gray)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedGenre == genre
                                            ? AnyShapeStyle(theme.buttonGradient)
                                            : AnyShapeStyle(.ultraThinMaterial)
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(selectedGenre == genre ? theme.rosePrimary.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 0.8)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)

                    Text("Игры (\(filteredGames.count))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)

                    LazyVStack(spacing: 12) {
                        ForEach(filteredGames) { game in
                            AppItemRow(app: game)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
            .background(theme.canvasBackground.ignoresSafeArea())
            .navigationTitle("Игры")
            .refreshable {
                catalog.loadCatalog()
            }
        }
    }
}
