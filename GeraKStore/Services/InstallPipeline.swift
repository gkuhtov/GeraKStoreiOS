import Foundation
import UIKit

public final class InstallPipeline: ObservableObject {
    public static let shared = InstallPipeline()
    
    @Published public var activeApp: AppItem? = nil
    @Published public var progress: Float = 0.0
    @Published public var statusDescription: String = ""

    private init() {}

    public func execute(app: AppItem, isClone: Bool = false, customName: String? = nil) {
        self.activeApp = app
        self.progress = 0.0
        self.statusDescription = "Скачивание..."
        
        HapticManager.shared.tap()
        BackgroundKeepAlive.shared.activate()
        LiveActivityManager.shared.startActivity(appName: app.name, iconUrl: app.iconUrl.absoluteString)

        // Слушаем живой прогресс байтов
        DownloadManager.shared.progressHandler = { [weak self] currentProgress in
            self?.progress = currentProgress * 0.7 // Первые 70% шкалы под загрузку
            self?.statusDescription = "Загрузка \(Int(currentProgress * 100))%"
            LiveActivityManager.shared.update(
                progress: currentProgress * 0.7,
                status: "Загрузка файла...",
                stage: "Загрузка"
            )
        }

        DownloadManager.shared.startDownload(from: app.downloadUrl) { [weak self] downloadedUrl in
            guard let self = self, let localIpa = downloadedUrl else {
                self?.handleFailure("Ошибка скачивания пакета")
                return
            }

            self.progress = 0.85
            self.statusDescription = "Подписание пакета..."
            LiveActivityManager.shared.update(progress: 0.85, status: "Подписание сертификатом...", stage: "Подпись")

            DispatchQueue.global(qos: .userInitiated).async {
                let finalBundleId = isClone ? "\(app.bundleId).clone" : app.bundleId
                let finalName = customName ?? app.name

                _ = InstallDispatcher.shared.generateManifest(
                    bundleId: finalBundleId,
                    version: app.version,
                    title: finalName,
                    ipaFileName: localIpa.lastPathComponent
                )

                DispatchQueue.main.async {
                    self.progress = 1.0
                    self.statusDescription = "Установка на рабочий стол..."
                    HapticManager.shared.success()
                    LiveActivityManager.shared.update(progress: 1.0, status: "Запуск установки", stage: "Установка")
                    
                    InstallDispatcher.shared.triggerInstallation(manifestEndpoint: "manifest.plist")

                    DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                        BackgroundKeepAlive.shared.deactivate()
                        LiveActivityManager.shared.end()
                        StorageManager.shared.purgeTempBuilds()
                        self.activeApp = nil
                        self.progress = 0.0
                        self.statusDescription = ""
                    }
                }
            }
        }
    }

    private func handleFailure(_ error: String) {
        HapticManager.shared.error()
        BackgroundKeepAlive.shared.deactivate()
        LiveActivityManager.shared.end()
        self.activeApp = nil
        self.progress = 0.0
        self.statusDescription = error
    }
}
