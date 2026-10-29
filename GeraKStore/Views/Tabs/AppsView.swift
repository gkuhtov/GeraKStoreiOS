import SwiftUI

public struct AppsView: View {
    @ObservedObject var catalog = CatalogService.shared
    @ObservedObject var theme = ThemeConfig.shared
    @State private var selectedFilter: String = "Все"

    public init() {}

    private var filteredApps: [AppItem] {
        if selectedFilter == "Все" {
            // Если нет разделения, показываем все приложения
            let appsOnly = catalog.apps.filter { $0.category == "apps" }
            return appsOnly.isEmpty ? catalog.apps : appsOnly
        }
        return catalog.apps.filter { $0.subcategory.localizedCaseInsensitiveContains(selectedFilter) }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.canvasBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Чипсы фильтра
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["Все", "Банки", "Фото и видео", "Музыка", "Соцсети"], id: \.self) { tag in
                                    Button(action: { selectedFilter = tag }) {
                                        Text(tag)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(selectedFilter == tag ? theme.rosePrimary : Color.white.opacity(0.08))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Заголовок со счетчиком
                        Text("Приложения (\(filteredApps.count))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)

                        // Список карточек
                        LazyVStack(spacing: 12) {
                            ForEach(filteredApps) { app in
                                NavigationLink(destination: AppDetailView(app: app)) {
                                    AppCardRow(app: app)
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
            .navigationTitle("Приложения")
        }
    }
}

public struct AppCardRow: View {
    let app: AppItem
    @ObservedObject var theme = ThemeConfig.shared
    @ObservedObject var pipeline = InstallPipeline.shared

    public var body: some View {
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
            .frame(width: 54, height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(app.subcategory)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    if app.isModded {
                        Text("МОД")
                            .font(.system(size: 9, weight: .bold))
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
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(theme.glassMaterial))
    }
}
