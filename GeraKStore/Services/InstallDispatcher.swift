import Foundation
import UIKit

public final class InstallDispatcher {
    public static let shared = InstallDispatcher()

    private init() {}

    public func generateLocalManifest(
        bundleId: String,
        version: String,
        title: String,
        ipaFileName: String
    ) -> URL? {
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
            return nil
        }
    }

    public func triggerInstallation(
        bundleId: String,
        version: String,
        title: String,
        ipaFileName: String,
        completion: @escaping (Bool) -> Void
    ) {
        OTAServer.shared.start()

        guard generateLocalManifest(
            bundleId: bundleId,
            version: version,
            title: title,
            ipaFileName: ipaFileName
        ) != nil else {
            completion(false)
            return
        }

        let itmsUrlString = "itms-services://?action=download-manifest&url=http://127.0.0.1:8080/manifest.plist"
        guard let itmsUrl = URL(string: itmsUrlString) else {
            completion(false)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIApplication.shared.open(itmsUrl, options: [:]) { success in
                completion(success)
            }
        }
    }
}
