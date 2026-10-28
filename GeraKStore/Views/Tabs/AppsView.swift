import SwiftUI

public struct AppsView: View {
    @ObservedObject var theme = ThemeConfig.shared
    @ObservedObject var catalog = CatalogService.shared
    @State private var selectedCategory = "Все"
    private let categories = ["Все", "Банки", "Фото и видео", "Музыка", "Соцсети", "Утилиты"]

    public init() {}

    private var filteredApps: [AppItem] {
        let apps = catalog.allApps.filter { $0.category == "apps" }
        if selectedCategory == "Все" {
            return apps
        }
        return apps.filter { $0.subcategory == selectedCategory }
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { cat in
                                Button(action: {
                                    HapticManager.shared.tap()
                                    selectedCategory = cat
                                }) {
                                    Text(cat)
                                        .font(.system(size: 14, weight: selectedCategory == cat ? .bold : .medium))
                                        .foregroundColor(selectedCategory == cat ? .white : .gray)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedCategory == cat
                                            ? AnyShapeStyle(theme.buttonGradient)
                                            : AnyShapeStyle(.ultraThinMaterial)
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(selectedCategory == cat ? theme.rosePrimary.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 0.8)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)

                    Text("Приложения (\(filteredApps.count))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)

                    LazyVStack(spacing: 12) {
                        ForEach(filteredApps) { app in
                            AppItemRow(app: app)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
            .background(theme.canvasBackground.ignoresSafeArea())
            .navigationTitle("Приложения")
            .refreshable {
                catalog.loadCatalog()
            }
        }
    }
}
