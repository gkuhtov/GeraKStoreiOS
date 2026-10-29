import Foundation
import UIKit

public final class InstallDispatcher {
    public static let shared = InstallDispatcher()

    private init() {}

    /// Генерирует XML-манифест для OTA-установки
    public func generateManifest(bundleId: String, version: String, title: String, ipaFileName: String) -> URL? {
        let signedDir = PathConfig.getDirectory(PathConfig.signedAppsFolder)
        let manifestUrl = signedDir.appendingPathComponent("manifest.plist")

        let xmlContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>items</key>
            <array>
                <dict>
                    <key>assets</key>
                    <array>
                        <dict>
                            <key>kind</key>
                            <string>software-package</string>
                            <key>url</key>
                            <string>http://127.0.0.1:8080/\(ipaFileName)</string>
                        </dict>
                    </array>
                    <key>metadata</key>
                    <dict>
                        <key>bundle-identifier</key>
                        <string>\(bundleId)</string>
                        <key>bundle-version</key>
                        <string>\(version)</string>
                        <key>kind</key>
                        <string>software</string>
                        <key>title</key>
                        <string>\(title)</string>
                    </dict>
                </dict>
            </array>
        </dict>
        </plist>
        """

        do {
            try xmlContent.write(to: manifestUrl, atomically: true, encoding: .utf8)
            return manifestUrl
        } catch {
            print("Ошибка записи manifest.plist: \(error.localizedDescription)")
            return nil
        }
    }

    /// Запускает сервер и инициирует установку через itms-services
    public func triggerInstallation(manifestEndpoint: String = "manifest.plist") {
        OTAServer.shared.start()

        let itmsUrlString = "itms-services://?action=download-manifest&url=http://127.0.0.1:8080/\(manifestEndpoint)"
        guard let url = URL(string: itmsUrlString) else { return }

        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("Запрос на установку успешно отправлен системе iOS")
                }
            }
        }
    }
}
