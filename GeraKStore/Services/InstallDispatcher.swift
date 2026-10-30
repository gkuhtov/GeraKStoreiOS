import Foundation
import UIKit

public final class InstallDispatcher {
    public static let shared = InstallDispatcher()

    private init() {}

    public func buildManifestContent(bundleId: String, version: String, title: String, ipaFileName: String) -> String {
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

        let plistXml = buildManifestContent(
            bundleId: bundleId,
            version: version,
            title: title,
            ipaFileName: ipaFileName
        )

        // Загрузка манифеста на защищенный HTTPS сервис (DPaste / анонимный raw SSL шлюз)
        guard let postData = "content=\(plistXml.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&expiry_days=1".data(using: .utf8),
              let serviceUrl = URL(string: "https://dpaste.com/api/v2/") else {
            completion(false)
            return
        }

        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.httpBody = postData
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data,
                  let rawUrlString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !rawUrlString.isEmpty else {
                completion(false)
                return
            }

            // Добавляем .txt / raw к ссылке для прямой отдачи XML
            let manifestHttpsUrl = rawUrlString.hasSuffix(".txt") ? rawUrlString : "\(rawUrlString).txt"
            let itmsUrlString = "itms-services://?action=download-manifest&url=\(manifestHttpsUrl)"

            guard let itmsUrl = URL(string: itmsUrlString) else {
                completion(false)
                return
            }

            DispatchQueue.main.async {
                UIApplication.shared.open(itmsUrl, options: [:]) { success in
                    completion(success)
                }
            }
        }.resume()
    }
}
