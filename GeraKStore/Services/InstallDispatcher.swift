import Foundation
import UIKit

public final class InstallDispatcher {
    public static let shared = InstallDispatcher()

    private init() {}

    public func buildManifestXml(hostIp: String, bundleId: String, version: String, title: String, ipaFileName: String) -> String {
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
                            <string>http://\(hostIp):8080/\(ipaFileName)</string>
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

        let hostIp = DeviceIPHelper.getLocalIPAddress()
        let xml = buildManifestXml(
            hostIp: hostIp,
            bundleId: bundleId,
            version: version,
            title: title,
            ipaFileName: ipaFileName
        )

        // Сохраняем локальную копию манифеста на случай прямого обращения
        let signedDir = PathConfig.getDirectory(PathConfig.signedAppsFolder)
        let manifestFile = signedDir.appendingPathComponent("manifest.plist")
        try? xml.write(to: manifestFile, atomically: true, encoding: .utf8)

        uploadManifest(xml: xml) { manifestHttpsUrl in
            guard let httpsUrl = manifestHttpsUrl,
                  let encodedUrl = httpsUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let itmsUrl = URL(string: "itms-services://?action=download-manifest&url=\(encodedUrl)") else {
                completion(false)
                return
            }

            DispatchQueue.main.async {
                UIApplication.shared.open(itmsUrl, options: [:]) { opened in
                    completion(opened)
                }
            }
        }
    }

    private func uploadManifest(xml: String, completion: @escaping (String?) -> Void) {
        guard let postData = xml.data(using: .utf8),
              let primaryServiceUrl = URL(string: "https://paste.rs/") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: primaryServiceUrl, timeoutInterval: 7)
        request.httpMethod = "POST"
        request.httpBody = postData
        request.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode),
               let data = data,
               let urlString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               urlString.hasPrefix("https://") {
                completion(urlString)
            } else {
                self.uploadManifestFallback(xml: xml, completion: completion)
            }
        }.resume()
    }

    private func uploadManifestFallback(xml: String, completion: @escaping (String?) -> Void) {
        guard let serviceUrl = URL(string: "https://dpaste.org/api/") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: serviceUrl, timeoutInterval: 7)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"format\"\r\n\r\nurl\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"content\"\r\n\r\n\(xml)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"expiry_days\"\r\n\r\n1\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, _ in
            if let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode),
               let data = data,
               let urlString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               urlString.hasPrefix("http") {
                let cleanUrl = urlString.replacingOccurrences(of: "\"", with: "")
                let rawUrl = cleanUrl.hasSuffix("/raw") ? cleanUrl : "\(cleanUrl)/raw"
                completion(rawUrl)
            } else {
                completion(nil)
            }
        }.resume()
    }
}
