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

                        Text("Приложения (\(filteredApps.count))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)

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
