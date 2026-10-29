import SwiftUI

public struct AppsView: View {
    @ObservedObject var catalog = CatalogService.shared
    @ObservedObject var theme = ThemeConfig.shared
    @State private var selectedFilter: String = "Все"

    public init() {}

    private var filteredApps: [AppItem] {
        if selectedFilter == "Все" {
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

                        // Состояние загрузки или пустой список со статусом
                        if catalog.isLoading && catalog.apps.isEmpty {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(.pink)
                                Text("Загрузка каталога...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if filteredApps.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "icloud.slash")
                                    .font(.system(size: 36))
                                    .foregroundColor(.secondary)
                                Text("Список пуст")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(catalog.lastStatus)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
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
                                ForEach(filteredApps) { app in
                                    NavigationLink(destination: ProductDetailView(app: app)) {
                                        AppCardRow(app: app)
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
            .navigationTitle("Приложения")
        }
    }
}
