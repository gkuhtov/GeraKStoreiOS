import SwiftUI

public struct ProductDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var theme = ThemeConfig.shared
    
    let app: AppItem
    
    @State private var screenshots: [URL] = []
    @State private var showVersionSheet = false
    @State private var showTweakOptions = false
    @State private var isDownloading = false
    @State private var downloadProgress: Float = 0.0

    public init(app: AppItem) {
        self.app = app
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                // 1. Шапка: Иконка, Заголовок, Кнопка загрузки
                HStack(spacing: 16) {
                    AsyncImage(url: app.iconUrl) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white.opacity(0.1))
                        }
                    }
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(app.subcategory)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)

                        HStack(spacing: 8) {
                            if isDownloading {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 7)
                                    .background(theme.buttonGradient)
                                    .clipShape(Capsule())
                            } else {
                                Button(action: {
                                    triggerFastInstall()
                                }) {
                                    Text("ЗАГРУЗИТЬ")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 7)
                                        .background(theme.buttonGradient)
                                        .clipShape(Capsule())
                                }
                                .contextMenu {
                                    Button {
                                        triggerFastInstall()
                                    } label: {
                                        Label("Быстрая установка", systemImage: "bolt.fill")
                                    }

                                    Button {
                                        showTweakOptions = true
                                    } label: {
                                        Label("Настроить перед установкой", systemImage: "slider.horizontal.3")
                                    }

                                    Button {
                                        HapticManager.shared.tap()
                                    } label: {
                                        Label("Экспорт IPA в Файлы", systemImage: "square.and.arrow.down")
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                // 2. Горизонтальная плашка метрик
                HStack {
                    MetricColumn(title: "ВЕРСИЯ", value: "\(app.version) ▼") {
                        if app.previousVersions?.isEmpty == false {
                            showVersionSheet = true
                        }
                    }

                    Divider().background(Color.white.opacity(0.15))

                    MetricColumn(title: "РАЗМЕР", value: app.size)

                    Divider().background(Color.white.opacity(0.15))

                    MetricColumn(title: "СОВМЕСТИМОСТЬ", value: "iOS \(app.minOSVersion)+")

                    Divider().background(Color.white.opacity(0.15))

                    MetricColumn(title: "ТИП", value: app.isModded ? "Мод" : "Оригинал")
                }
                .frame(height: 52)
                .padding(.horizontal, 12)
                .liquidGlass()
                .padding(.horizontal, 20)

                // 3. Галерея официальных скриншотов
                if !screenshots.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Предпросмотр")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(screenshots, id: \.self) { url in
                                    AsyncImage(url: url) { phase in
                                        if let img = phase.image {
                                            img.resizable().scaledToFill()
                                        } else {
                                            Rectangle().fill(Color.white.opacity(0.05))
                                        }
                                    }
                                    .frame(width: 170, height: 320)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 0.8)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }

                // 4. Описание
                VStack(alignment: .leading, spacing: 8) {
                    Text("Описание")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(app.description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 20)

                // 5. Блок безопасности и целостности
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(theme.roseSecondary)
                            .font(.system(size: 16))

                        Text("Безопасность и подпись")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        SecurityRow(label: "Происхождение", value: app.isModded ? "Модифицированный пакет" : "Официальный App Store Dump")
                        
                        if let author = app.tweakAuthor {
                            SecurityRow(label: "Автор твика", value: author)
                        }

                        SecurityRow(label: "Статус бинарника", value: "Очищен от отслеживания")
                        
                        if let hash = app.sha256 {
                            SecurityRow(label: "SHA-256", value: String(hash.prefix(16)) + "...")
                        }
                    }
                }
                .padding(16)
                .liquidGlass()
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
        .background(theme.canvasBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            iTunesLookupService.shared.fetchScreenshots(bundleId: app.bundleId) { urls in
                self.screenshots = urls
            }
        }
        .sheet(isPresented: $showVersionSheet) {
            VersionSelectionSheet(app: app)
        }
        .sheet(isPresented: $showTweakOptions) {
            TweakInstallSheet(app: app)
        }
    }

    private func triggerFastInstall() {
        HapticManager.shared.tap()
        isDownloading = true
        InstallPipeline.shared.execute(app: app)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isDownloading = false
        }
    }
}

private struct MetricColumn: View {
    let title: String
    let value: String
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)

                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .disabled(onTap == nil)
    }
}

private struct SecurityRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
    }
}
