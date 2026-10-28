import Foundation
import Security

public struct CertificateInfo {
    public let name: String
    public let teamIdentifier: String
    public let expirationDate: Date
    public let daysRemaining: Int
    public let isExpired: Bool
    public let provisionedDevices: [String]
}

public final class CertificateHealthValidator: ObservableObject {
    public static let shared = CertificateHealthValidator()

    @Published public var currentCertInfo: CertificateInfo? = nil
    @Published public var isValid: Bool = false

    private init() {
        validateStoredProvisionProfile()
    }

    /// Проверяет наличие и валидность сохраненного .mobileprovision
    public func validateStoredProvisionProfile() {
        let certsDir = PathConfig.getDirectory(PathConfig.certificatesFolder)
        let fileManager = FileManager.default

        guard let files = try? fileManager.contentsOfDirectory(at: certsDir, includingPropertiesForKeys: nil) else {
            self.isValid = false
            return
        }

        // Ищем файл с расширением .mobileprovision
        if let provisionUrl = files.first(where: { $0.pathExtension == "mobileprovision" }) {
            parseProfile(at: provisionUrl)
        }
    }

    /// Парсит ASN.1 / XML-контейнер мобильного профиля
    public func parseProfile(at url: URL) {
        guard let data = try? Data(contentsOf: url) else { return }

        // Извлекаем чистый XML-блок из подписанного CMS-контейнера
        guard let xmlString = extractXMLFromProvision(data: data),
              let xmlData = xmlString.data(using: .utf8) else {
            return
        }

        do {
            var format = PropertyListSerialization.PropertyListFormat.xml
            guard let plist = try PropertyListSerialization.propertyList(from: xmlData, options: [], format: &format) as? [String: Any] else {
                return
            }

            let name = plist["Name"] as? String ?? "Сертификат разработчика"
            let expirationDate = plist["ExpirationDate"] as? Date ?? Date()
            let teamId = (plist["TeamIdentifier"] as? [String])?.first ?? "UNKNOWN"
            let devices = plist["ProvisionedDevices"] as? [String] ?? []

            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: Date(), to: expirationDate)
            let days = max(0, components.day ?? 0)
            let expired = expirationDate < Date()

            DispatchQueue.main.async {
                self.currentCertInfo = CertificateInfo(
                    name: name,
                    teamIdentifier: teamId,
                    expirationDate: expirationDate,
                    daysRemaining: days,
                    isExpired: expired,
                    provisionedDevices: devices
                )
                self.isValid = !expired
            }
        } catch {
            print("Ошибка парсинга mobileprovision: \(error.localizedDescription)")
        }
    }

    /// Очистка подписи ASN.1 и поиск границ PLIST
    private func extractXMLFromProvision(data: Data) -> String? {
        guard let fullString = String(data: data, encoding: .isoLatin1) else { return nil }

        let startTag = "<?xml"
        let endTag = "</plist>"

        guard let startRange = fullString.range(of: startTag),
              let endRange = fullString.range(of: endTag) else {
            return nil
        }

        let plistContent = fullString[startRange.lowerBound..<endRange.upperBound]
        return String(plistContent)
    }
}
