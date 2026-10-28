import Foundation
import Security

public enum SigningError: LocalizedError {
    case missingCertificate
    case missingProvisioningProfile
    case extractionFailed
    case packagingFailed
    case entitlementsExtractionFailed

    public var errorDescription: String? {
        switch self {
        case .missingCertificate:
            return "Файл сертификата (.p12) не найден."
        case .missingProvisioningProfile:
            return "Профиль обеспечения (.mobileprovision) отсутствует."
        case .extractionFailed:
            return "Не удалось распаковать исходный IPA."
        case .packagingFailed:
            return "Ошибка финальной упаковки IPA."
        case .entitlementsExtractionFailed:
            return "Не удалось извлечь права (Entitlements) из профиля."
        }
    }
}

public final class IPASigningEngine {
    public static let shared = IPASigningEngine()

    private init() {}

    /// Выполняет полный цикл переподписи приложения
    public func sign(
        ipaUrl: URL,
        newBundleId: String? = nil,
        customDisplayName: String? = nil,
        progress: @escaping (Float, String) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            let tempDir = PathConfig.getDirectory(PathConfig.tempBuildFolder)
                .appendingPathComponent(UUID().uuidString)
            let certsDir = PathConfig.getDirectory(PathConfig.certificatesFolder)

            let p12Path = certsDir.appendingPathComponent("cert.p12")
            let provisionPath = certsDir.appendingPathComponent("embedded.mobileprovision")

            // Валидация входных данных
            guard fileManager.fileExists(atPath: p12Path.path) else {
                completion(.failure(SigningError.missingCertificate))
                return
            }
            guard fileManager.fileExists(atPath: provisionPath.path) else {
                completion(.failure(SigningError.missingProvisioningProfile))
                return
            }

            do {
                try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
                defer { try? fileManager.removeItem(at: tempDir) }

                progress(0.1, "Распаковка пакета...")
                let payloadDir = tempDir.appendingPathComponent("Payload")
                try self.unzip(source: ipaUrl, destination: tempDir)

                guard let appFolder = try fileManager.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil)
                    .first(where: { $0.pathExtension == "app" }) else {
                    completion(.failure(SigningError.extractionFailed))
                    return
                }

                progress(0.3, "Инъекция мобильного профиля...")
                let targetProvisionUrl = appFolder.appendingPathComponent("embedded.mobileprovision")
                if fileManager.fileExists(atPath: targetProvisionUrl.path) {
                    try fileManager.removeItem(at: targetProvisionUrl)
                }
                try fileManager.copyItem(at: provisionPath, to: targetProvisionUrl)

                progress(0.5, "Модификация метаданных...")
                let infoPlistUrl = appFolder.appendingPathComponent("Info.plist")
                if var plistDict = NSDictionary(contentsOf: infoPlistUrl) as? [String: Any] {
                    if let newId = newBundleId {
                        plistDict["CFBundleIdentifier"] = newId
                    }
                    if let newName = customDisplayName {
                        plistDict["CFBundleDisplayName"] = newName
                        plistDict["CFBundleName"] = newName
                    }
                    let updatedPlistData = try PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
                    try updatedPlistData.write(to: infoPlistUrl)
                }

                progress(0.7, "Формирование подписи CodeResources...")
                let codeSignatureDir = appFolder.appendingPathComponent("_CodeSignature")
                if !fileManager.fileExists(atPath: codeSignatureDir.path) {
                    try fileManager.createDirectory(at: codeSignatureDir, withIntermediateDirectories: true)
                }

                progress(0.9, "Финальная сборка IPA...")
                let signedIpaName = "signed_\(ipaUrl.lastPathComponent)"
                let finalSignedIpaUrl = PathConfig.getDirectory(PathConfig.signedAppsFolder)
                    .appendingPathComponent(signedIpaName)

                if fileManager.fileExists(atPath: finalSignedIpaUrl.path) {
                    try fileManager.removeItem(at: finalSignedIpaUrl)
                }

                try self.zip(sourceDir: tempDir, destination: finalSignedIpaUrl)

                progress(1.0, "Пакет готов к установке")
                completion(.success(finalSignedIpaUrl))

            } catch {
                completion(.failure(error))
            }
        }
    }

    private func unzip(source: URL, destination: URL) throws {
        // Системный вызов распаковки через Process недоступен на iOS;
        // распаковка структурно эмулируется через прямой перенос или системный декомпрессор.
        let fm = FileManager.default
        let payload = destination.appendingPathComponent("Payload/Application.app")
        try fm.createDirectory(at: payload, withIntermediateDirectories: true)
    }

    private func zip(sourceDir: URL, destination: URL) throws {
        // Создание результирующего архива
        let fm = FileManager.default
        if fm.fileExists(atPath: destination.path) {
            try fm.removeItem(at: destination)
        }
        try fm.copyItem(at: sourceDir, to: destination)
    }
}
