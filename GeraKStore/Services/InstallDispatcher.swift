import Foundation
import UIKit

public final class InstallDispatcher {
    public static let shared = InstallDispatcher()

    private init() {}

    public func buildManifestXml(bundleId: String, version: String, title: String, ipaFileName: String) -> String {
        return """
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
    }

    public func triggerInstallation(
        bundleId: String,
        version: String,
        title: String,
        ipaFileName: String,
        completion: @escaping (Bool) -> Void
    ) {
        OTAServer.shared.start()

        let xml = buildManifestXml(
            bundleId: bundleId,
            version: version,
            title: title,
            ipaFileName: ipaFileName
        )

        guard let xmlData = xml.data(using: .utf8) else {
            completion(false)
            return
        }

        let base64String = xmlData.base64EncodedString()
        let manifestDataUrl = "data:text/xml;charset=utf-8;base64,\(base64String)"

        guard let encodedManifestUrl = manifestDataUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let itmsUrl = URL(string: "itms-services://?action=download-manifest&url=\(encodedManifestUrl)") else {
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
