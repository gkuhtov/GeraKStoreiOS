import SwiftUI

public struct TodayView: View {
    @ObservedObject var catalog = CatalogService.shared
    @ObservedObject var theme = ThemeConfig.shared
    @State private var hasCertificate: Bool = false
    @State private var showSettingsSheet: Bool = false

    public init() {}

    private var recentApps: [AppItem] {
        Array(catalog.apps.prefix(5))
    }

    private func checkCertStatus() {
        let certsDir = PathConfig.getDirectory(PathConfig.certificatesFolder)
        let p12Path = certsDir.appendingPathComponent("cert.p12").path
        let provPath = certsDir.appendingPathComponent("embedded.mobileprovision").path
        hasCertificate = FileManager.default.fileExists(atPath: p12Path) && FileManager.default.fileExists(atPath: provPath)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.canvasBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Динамическая плашка статуса сертификата (нажатие ведет в настройки)
                        Button(action: { showSettingsSheet = true }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label(
                                        hasCertificate ? "СЕРТИФИКАТ АКТИВЕН" : "СЕРТИФИКАТ НЕ НАЙДЕН",
                                        systemImage: hasCertificate ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
                                    )
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(hasCertificate ? .pink : .orange)

                                    Spacer()

                                    Text(hasCertificate ? "Готов к работе" : "Требуется импорт")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }

                                Text(hasCertificate ? "Готов к установке и подписи" : "Настроить сертификат разработчика")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)

                                Text(
                                    hasCertificate
                                    ? "Все приложения из каталога будут автоматически подписаны вашим профилем."
                                    : "Нажмите здесь, чтобы импортировать .p12 и .mobileprovision."
                                )
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            }
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 18).fill(theme.glassMaterial))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(hasCertificate ? Color.pink.opacity(0.3) : Color.orange.opacity(0.4), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
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
                    checkCertStatus()
                    catalog.loadCatalog()
                }
                .onAppear {
                    checkCertStatus()
                }
            }
            .navigationTitle("Сегодня")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettingsSheet = true }) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.pink)
                    }
                }
            }
            .sheet(isPresented: $showSettingsSheet, onDismiss: checkCertStatus) {
                SettingsView()
            }
        }
    }
}
