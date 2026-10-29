import Foundation
import UIKit

public final class InstallDispatcher {
    public static let shared = InstallDispatcher()

    private init() {}

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
                            <string>https://127.0.0.1:8443/\(ipaFileName)</string>
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
            return nil
        }
    }

    public func triggerInstallation() {
        OTAServer.shared.start()

        let itmsUrlString = "itms-services://?action=download-manifest&url=https://127.0.0.1:8443/manifest.plist"
        guard let url = URL(string: itmsUrlString) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIApplication.shared.open(url, options: [:]) { _ in }
        }
    }
}
