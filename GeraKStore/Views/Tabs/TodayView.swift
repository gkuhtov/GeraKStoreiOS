import SwiftUI

public struct TodayView: View {
    @ObservedObject var catalog = CatalogService.shared
    @ObservedObject var theme = ThemeConfig.shared
    @State private var hasCertificate: Bool = false
    @State private var showSettingsSheet: Bool = false
    @State private var showSuccessBanner: Bool = false

    public init() {}

    private var recentApps: [AppItem] {
        Array(catalog.apps.prefix(5))
    }

    private func checkCertStatus() {
        let certsDir = PathConfig.getDirectory(PathConfig.certificatesFolder)
        let p12Path = certsDir.appendingPathComponent("cert.p12").path
        let provPath = certsDir.appendingPathComponent("embedded.mobileprovision").path
        let certInstalled = FileManager.default.fileExists(atPath: p12Path) && FileManager.default.fileExists(atPath: provPath)

        if !hasCertificate && certInstalled {
            // Только что импортировали сертификат
            withAnimation(.spring()) {
                showSuccessBanner = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation {
                    showSuccessBanner = false
                }
            }
        }
        withAnimation {
            hasCertificate = certInstalled
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                theme.canvasBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        
                        // Если сертификат НЕ импортирован — показываем баннер с призывом импорта
                        if !hasCertificate {
                            Button(action: { showSettingsSheet = true }) {
                                HStack(spacing: 14) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.orange)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Требуется импорт сертификата")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("Нажмите для импорта .p12 и .mobileprovision")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 16).fill(theme.glassMaterial))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Список приложений репозитория
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Каталог репозитория")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)

                            if recentApps.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        ProgressView().tint(.pink)
                                        Text(catalog.lastStatus)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 24)
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
                    .padding(.top, 12)
                }
                .refreshable {
                    checkCertStatus()
                    catalog.loadCatalog()
                }

                // Всплывающая плашка успеха
                if showSuccessBanner {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 18))
                        Text("Сертификат успешно активирован!")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.9)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.green.opacity(0.5), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle("Сегодня")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettingsSheet = true }) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(hasCertificate ? .green : .pink)
                    }
                }
            }
            .sheet(isPresented: $showSettingsSheet, onDismiss: checkCertStatus) {
                SettingsView()
            }
            .onAppear(perform: checkCertStatus)
        }
    }
}
