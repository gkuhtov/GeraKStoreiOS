import SwiftUI

public struct SearchView: View {
    @ObservedObject var catalog = CatalogService.shared
    @ObservedObject var theme = ThemeConfig.shared
    @ObservedObject var pipeline = InstallPipeline.shared
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
                                HStack(spacing: 12) {
                                    AsyncImage(url: app.iconUrl) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable().scaledToFill()
                                        default:
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.gray.opacity(0.3))
                                        }
                                    }
                                    .frame(width: 52, height: 52)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(app.name)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)

                                        HStack(spacing: 6) {
                                            Text(app.subcategory)
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)

                                            if app.isModded {
                                                Text("мод")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.pink)
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 1)
                                                    .background(Color.pink.opacity(0.15))
                                                    .cornerRadius(4)
                                            }
                                        }
                                    }

                                    Spacer()

                                    Button(action: {
                                        pipeline.execute(app: app)
                                    }) {
                                        Text(pipeline.activeApp?.id == app.id ? pipeline.statusDescription : "ЗАГРУЗИТЬ")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(theme.buttonGradient)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 16).fill(theme.glassMaterial))
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
