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

        let xml = buildManifestXml(bundleId: bundleId, version: version, title: title, ipaFileName: ipaFileName)

        // Строгое RFC3986 percent-encoding
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let encodedXml = xml.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let bodyString = "content=\(encodedXml)&expiry_days=1"

        guard let bodyData = bodyString.data(using: .utf8),
              let url = URL(string: "https://dpaste.com/api/v2/") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("GeraKStore/1.0", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode >= 200, httpRes.statusCode < 300,
               let data = data,
               let rawUrl = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               rawUrl.hasPrefix("http") {

                let rawManifestUrl = rawUrl.hasSuffix(".txt") ? rawUrl : "\(rawUrl).txt"
                let itmsUrlString = "itms-services://?action=download-manifest&url=\(rawManifestUrl)"

                guard let itmsUrl = URL(string: itmsUrlString) else {
                    completion(false)
                    return
                }

                DispatchQueue.main.async {
                    UIApplication.shared.open(itmsUrl, options: [:]) { opened in
                        completion(opened)
                    }
                }
            } else {
                completion(false)
            }
        }.resume()
    }
}
