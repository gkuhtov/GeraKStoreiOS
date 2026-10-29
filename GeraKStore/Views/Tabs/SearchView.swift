import SwiftUI

public struct SearchView: View {
    @ObservedObject var catalog = CatalogService.shared
    @ObservedObject var theme = ThemeConfig.shared
    @State private var searchText: String = ""

    public init() {}

    private var searchResults: [AppItem] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }
        return catalog.apps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.subcategory.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.canvasBackground.ignoresSafeArea()

                if searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Ничего не найдено")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                } else if searchResults.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkle.magnifyingglass")
                            .font(.system(size: 44))
                            .foregroundColor(theme.rosePrimary.opacity(0.8))
                        Text("Введите название приложения или твика")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(searchResults) { app in
                                AppRowView(app: app)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Поиск в GeraKStore")
            .navigationTitle("Поиск")
        }
    }
}
