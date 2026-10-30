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

        // 1. Скачивание IPA
        DownloadManager.shared.progressHandler = { [weak self] currentProgress in
            let mappedProgress = currentProgress * 0.4
            self?.progress = mappedProgress
            self?.statusDescription = "Загрузка \(Int(currentProgress * 100))%"
        }

        DownloadManager.shared.startDownload(from: app.downloadUrl) { [weak self] downloadedUrl in
            guard let self = self, let localIpa = downloadedUrl else {
                self?.handleFailure("Не удалось скачать IPA-файл.")
                return
            }

            // 2. Локальная переподпись zsign
            let targetBundleId = IPASigningEngine.shared.extractBundleIdFromProvision() ?? (isClone ? "\(app.bundleId).clone" : app.bundleId)
            let targetTitle = customName ?? app.name

            IPASigningEngine.shared.sign(
                ipaUrl: localIpa,
                newBundleId: targetBundleId,
                customDisplayName: targetTitle,
                progress: { [weak self] signProgress, signStatus in
                    DispatchQueue.main.async {
                        let totalProgress = 0.4 + (signProgress * 0.5)
                        self?.progress = totalProgress
                        self?.statusDescription = signStatus
                    }
                },
                completion: { [weak self] result in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let signedIpaUrl):
                            self.progress = 0.95
                            self.statusDescription = "Установка..."

                            InstallDispatcher.shared.triggerInstallation(
                                bundleId: targetBundleId,
                                version: app.version,
                                title: targetTitle,
                                ipaFileName: signedIpaUrl.lastPathComponent
                            ) { success in
                                if success {
                                    self.progress = 1.0
                                    HapticManager.shared.success()

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                                        BackgroundKeepAlive.shared.deactivate()
                                        self.activeApp = nil
                                        self.progress = 0.0
                                        self.statusDescription = ""
                                    }
                                } else {
                                    self.handleFailure("Не удалось открыть команду установки.")
                                }
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
        DispatchQueue.main.async {
            HapticManager.shared.error()
            BackgroundKeepAlive.shared.deactivate()
            self.lastErrorMessage = error
            self.activeApp = nil
            self.progress = 0.0
            self.statusDescription = ""

            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                let alert = UIAlertController(title: "Ошибка", message: error, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Понятно", style: .default))
                rootVC.present(alert, animated: true)
            }
        }
    }
}
