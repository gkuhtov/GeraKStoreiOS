import Foundation
import UIKit

public final class InstallPipeline: ObservableObject {
    public static let shared = InstallPipeline()
    
    @Published public var activeApp: AppItem? = nil
    @Published public var progress: Float = 0.0
    @Published public var statusDescription: String = ""
    @Published public var lastErrorMessage: String? = nil

    private init() {}

    public func execute(app: AppItem, isClone: Bool = false, customName: String? = nil) {
        self.activeApp = app
        self.progress = 0.0
        self.statusDescription = "Загрузка..."
        self.lastErrorMessage = nil
        
        HapticManager.shared.tap()
        BackgroundKeepAlive.shared.activate()

        // 1. Скачивание
        DownloadManager.shared.progressHandler = { [weak self] currentProgress in
            let mappedProgress = currentProgress * 0.5
            self?.progress = mappedProgress
            self?.statusDescription = "Загрузка \(Int(currentProgress * 100))%"
        }

        DownloadManager.shared.startDownload(from: app.downloadUrl) { [weak self] downloadedUrl in
            guard let self = self, let localIpa = downloadedUrl else {
                self?.handleFailure("Не удалось скачать IPA-файл по ссылке.")
                return
            }

            // 2. Подпись
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
                    }
                },
                completion: { [weak self] result in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let signedIpaUrl):
                            // 3. Регистрация манифеста и OTA
                            self.progress = 0.95
                            self.statusDescription = "Подготовка..."

                            _ = InstallDispatcher.shared.generateManifest(
                                bundleId: targetBundleId,
                                version: app.version,
                                title: targetTitle,
                                ipaFileName: signedIpaUrl.lastPathComponent
                            )

                            self.progress = 1.0
                            self.statusDescription = "Установка..."
                            HapticManager.shared.success()

                            InstallDispatcher.shared.triggerInstallation(manifestEndpoint: "manifest.plist")

                            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                                BackgroundKeepAlive.shared.deactivate()
                                StorageManager.shared.purgeTempBuilds()
                                self.activeApp = nil
                                self.progress = 0.0
                                self.statusDescription = ""
                            }

                        case .failure(let error):
                            self.handleFailure("Ошибка подписи: \(error.localizedDescription)")
                        }
                    }
                }
            )
        }
    }

    private func handleFailure(_ error: String) {
        DispatchQueue.main.async {
            HapticManager.shared.error()
            BackgroundKeepAlive.shared.deactivate()
            self.lastErrorMessage = error
            self.activeApp = nil
            self.progress = 0.0
            self.statusDescription = ""
            
            // Показ нативного системного уведомления
            if let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController {
                let alert = UIAlertController(title: "Ошибка установки", message: error, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Понятно", style: .default))
                rootVC.present(alert, animated: true)
            }
        }
    }
}
