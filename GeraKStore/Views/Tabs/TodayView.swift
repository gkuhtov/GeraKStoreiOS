import SwiftUI

public struct TodayView: View {
    @ObservedObject var catalog = CatalogService.shared
    @ObservedObject var theme = ThemeConfig.shared

    public init() {}

    private var recentApps: [AppItem] {
        Array(catalog.apps.prefix(5))
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.canvasBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Верхняя плашка сертификата
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("СЕРТИФИКАТ АКТИВЕН", systemImage: "checkmark.seal.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.pink)
                                Spacer()
                                Text("312 дней")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }

                            Text("Готов к установке и подписи")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)

                            Text("Все приложения из каталога будут автоматически подписаны вашим профилем разработчика.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 18).fill(theme.glassMaterial))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)

                        // Список свежих релизов
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Каталог репозитория")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)

                            if recentApps.isEmpty {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(.pink)
                                        .padding(.vertical, 20)
                                    Spacer()
                                }
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(recentApps) { app in
                                        NavigationLink(destination: ProductDetailView(app: app)) {
                                            AppCardRow(app: app)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                .refreshable {
                    catalog.loadCatalog()
                }
            }
            .navigationTitle("Сегодня")
        }
    }
}
