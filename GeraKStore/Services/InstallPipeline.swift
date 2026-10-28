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
        self.statusDescription = "Загрузка..."
        
        HapticManager.shared.tap()
        BackgroundKeepAlive.shared.activate()
        LiveActivityManager.shared.startActivity(appName: app.name, iconUrl: app.iconUrl.absoluteString)

        // Этап 1: Скачивание (0.0 -> 0.5)
        DownloadManager.shared.progressHandler = { [weak self] currentProgress in
            let mappedProgress = currentProgress * 0.5
            self?.progress = mappedProgress
            self?.statusDescription = "Загрузка \(Int(currentProgress * 100))%"
            LiveActivityManager.shared.update(
                progress: mappedProgress,
                status: "Загрузка архива...",
                stage: "Загрузка"
            )
        }

        DownloadManager.shared.startDownload(from: app.downloadUrl) { [weak self] downloadedUrl in
            guard let self = self, let localIpa = downloadedUrl else {
                self?.handleFailure("Ошибка загрузки файла")
                return
            }

            // Этап 2: Подписание (0.5 -> 0.9)
            let targetBundleId = isClone ? "\(app.bundleId).clone" : app.bundleId
            let targetTitle = customName ?? app.name

            IPASigningEngine.shared.sign(
                ipaUrl: localIpa,
                newBundleId: targetBundleId,
                customDisplayName: targetTitle,
                progress: { [weak self] signProgress, signStatus in
                    DispatchQueue.main.async {
                        let totalProgress = 0.5 + (signProgress * 0.4)
                        self?.progress = totalProgress
                        self?.statusDescription = signStatus
                        LiveActivityManager.shared.update(
                            progress: totalProgress,
                            status: signStatus,
                            stage: "Подпись"
                        )
                    }
                },
                completion: { [weak self] result in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let signedIpaUrl):
                            // Этап 3: Регистрация манифеста и запуск OTA
                            self.progress = 0.95
                            self.statusDescription = "Подготовка установки..."

                            _ = InstallDispatcher.shared.generateManifest(
                                bundleId: targetBundleId,
                                version: app.version,
                                title: targetTitle,
                                ipaFileName: signedIpaUrl.lastPathComponent
                            )

                            self.progress = 1.0
                            self.statusDescription = "Установка..."
                            HapticManager.shared.success()
                            LiveActivityManager.shared.update(
                                progress: 1.0,
                                status: "Запуск установки",
                                stage: "Установка"
                            )

                            InstallDispatcher.shared.triggerInstallation(manifestEndpoint: "manifest.plist")

                            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                                BackgroundKeepAlive.shared.deactivate()
                                LiveActivityManager.shared.end()
                                StorageManager.shared.purgeTempBuilds()
                                self.activeApp = nil
                                self.progress = 0.0
                                self.statusDescription = ""
                            }

                        case .failure(let error):
                            self.handleFailure(error.localizedDescription)
                        }
                    }
                }
            )
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
