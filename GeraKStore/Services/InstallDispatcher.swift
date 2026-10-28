import Foundation
import UIKit

public final class InstallDispatcher {
    public static let shared = InstallDispatcher()

    private init() {}

    /// Генерирует XML-манифест для iOS OTA-установщика
    public func generateManifest(bundleId: String, version: String, title: String, ipaFileName: String) -> URL? {
        let port = StoreConfig.localServerPort
        let host = StoreConfig.localServerHost
        let ipaUrl = "http://\(host):\(port)/download/\(ipaFileName)"

        let plistContent = """
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
                            <string>\(ipaUrl)</string>
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

        let tempDir = PathConfig.getDirectory(PathConfig.tempCacheFolder)
        let manifestFile = tempDir.appendingPathComponent("manifest.plist")

        do {
            try plistContent.write(to: manifestFile, atomically: true, encoding: .utf8)
            return manifestFile
        } catch {
            print("Ошибка записи manifest.plist: \(error.localizedDescription)")
            return nil
        }
    }

    /// Открывает системную ссылку itms-services для запуска установки
    public func triggerInstallation(manifestEndpoint: String = "manifest.plist") {
        let port = StoreConfig.localServerPort
        let host = StoreConfig.localServerHost
        let installString = "itms-services://?action=download-manifest&url=http://\(host):\(port)/\(manifestEndpoint)"

        guard let url = URL(string: installString) else { return }

        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}
