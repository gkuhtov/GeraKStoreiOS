import Foundation
import Security

struct CertificateHealth: Equatable {
    enum Status: Equatable {
        case missing
        case readable
        case expired
        case invalid
    }

    let status: Status
    let expirationDate: Date?
    let teamIdentifier: String?
    let bundleIdentifiers: [String]
    let deviceUDIDs: [String]
    let message: String
}

enum CertificateHealthValidator {
    /// Performs basic local checks on a provisioning profile.
    /// Cryptographic verification and .p12 private-key import are separate operations.
    static func inspectProvisioningProfile(at url: URL, now: Date = .now) -> CertificateHealth {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return CertificateHealth(
                status: .missing, expirationDate: nil, teamIdentifier: nil,
                bundleIdentifiers: [], deviceUDIDs: [], message: "Профиль не найден."
            )
        }

        do {
            let data = try Data(contentsOf: url)
            guard let plistData = extractPlist(from: data),
                  let plist = try PropertyListSerialization.propertyList(
                    from: plistData, options: [], format: nil
                  ) as? [String: Any] else {
                return CertificateHealth(
                    status: .invalid, expirationDate: nil, teamIdentifier: nil,
                    bundleIdentifiers: [], deviceUDIDs: [], message: "Не удалось прочитать provisioning profile."
                )
            }

            let expiration = plist["ExpirationDate"] as? Date
            let entitlements = plist["Entitlements"] as? [String: Any] ?? [:]
            let applicationIdentifier = entitlements["application-identifier"] as? String
            let bundleIDs = applicationIdentifier.map { [$0] } ?? []
            let teamIDs = plist["TeamIdentifier"] as? [String]
            let teamID = teamIDs?.first
            let devices = plist["ProvisionedDevices"] as? [String] ?? []

            if let expiration, expiration <= now {
                return CertificateHealth(
                    status: .expired, expirationDate: expiration, teamIdentifier: teamID,
                    bundleIdentifiers: bundleIDs, deviceUDIDs: devices,
                    message: "Срок действия профиля истёк."
                )
            }

            return CertificateHealth(
                status: .readable, expirationDate: expiration, teamIdentifier: teamID,
                bundleIdentifiers: bundleIDs, deviceUDIDs: devices,
                message: "Профиль прочитан. Криптографическая подпись отдельно не проверялась."
            )
        } catch {
            return CertificateHealth(
                status: .invalid, expirationDate: nil, teamIdentifier: nil,
                bundleIdentifiers: [], deviceUDIDs: [], message: "Ошибка чтения: \(error.localizedDescription)"
            )
        }
    }

    /// Imports a PKCS#12 identity into a temporary in-memory result.
    /// The caller must never persist the password or private key in logs/UserDefaults.
    static func validatePKCS12(at url: URL, password: String) -> Bool {
        guard let data = try? Data(contentsOf: url) else { return false }
        let options = [kSecImportExportPassphrase as String: password] as CFDictionary
        var items: CFArray?
        let status = SecPKCS12Import(data as CFData, options, &items)
        guard status == errSecSuccess,
              let imported = items as? [[String: Any]],
              let first = imported.first,
              first[kSecImportItemIdentity as String] is SecIdentity else {
            return false
        }
        return true
    }

    private static func extractPlist(from data: Data) -> Data? {
        if let start = data.range(of: Data("<?xml".utf8)),
           let end = data.range(of: Data("</plist>".utf8), options: .backwards) {
            return data.subdata(in: start.lowerBound..<end.upperBound)
        }
        if let start = data.range(of: Data("<plist".utf8)),
           let end = data.range(of: Data("</plist>".utf8), options: .backwards) {
            return data.subdata(in: start.lowerBound..<end.upperBound)
        }
        return nil
    }
}
