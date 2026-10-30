import Foundation

@_silgen_name("run_zsign_direct")
func run_zsign_direct(
    _ ipa_path: UnsafePointer<CChar>?,
    _ p12_path: UnsafePointer<CChar>?,
    _ password: UnsafePointer<CChar>?,
    _ provision_path: UnsafePointer<CChar>?,
    _ output_path: UnsafePointer<CChar>?,
    _ bundle_id: UnsafePointer<CChar>?,
    _ display_name: UnsafePointer<CChar>?,
    _ temp_dir: UnsafePointer<CChar>?,
    _ error_log: UnsafeMutablePointer<CChar>?,
    _ max_log_len: Int32
) -> Int32

public enum SigningError: LocalizedError {
    case missingCertificate
    case missingProvisioningProfile
    case invalidSourceFile
    case executionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingCertificate:
            return "Файл сертификата (.p12) не найден. Добавьте его в Настройках."
        case .missingProvisioningProfile:
            return "Профиль (.mobileprovision) не найден. Добавьте его в Настройках."
        case .invalidSourceFile:
            return "Скачанный IPA-файл поврежден или отсутствует."
        case .executionFailed(let details):
            return details
        }
    }
}

public final class IPASigningEngine {
    public static let shared = IPASigningEngine()

    private init() {}

    public func extractBundleIdFromProvision() -> String? {
        let certsDir = PathConfig.getDirectory(PathConfig.certificatesFolder)
        let provisionPath = certsDir.appendingPathComponent("embedded.mobileprovision")
        guard let data = try? Data(contentsOf: provisionPath),
              let stringContent = String(data: data, encoding: .isoLatin1) else {
            return nil
        }

        // Ищем application-identifier в XML блоке mobileprovision
        if let rangeStart = stringContent.range(of: "<key>application-identifier</key>"),
           let stringTagStart = stringContent.range(of: "<string>", range: rangeStart.upperBound..<stringContent.endIndex),
           let stringTagEnd = stringContent.range(of: "</string>", range: stringTagStart.upperBound..<stringContent.endIndex) {
            let fullAppId = String(stringContent[stringTagStart.upperBound..<stringTagEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            // Формат TeamID.bundleId -> отсекаем TeamID
            if let dotIndex = fullAppId.firstIndex(of: ".") {
                let parsed = String(fullAppId[fullAppId.index(after: dotIndex)...])
                if parsed != "*" {
                    return parsed
                }
            }
        }
        return nil
    }

    public func sign(
        ipaUrl: URL,
        newBundleId: String? = nil,
        customDisplayName: String? = nil,
        progress: @escaping (Float, String) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            let certsDir = PathConfig.getDirectory(PathConfig.certificatesFolder)
            let p12Path = certsDir.appendingPathComponent("cert.p12")
            let provisionPath = certsDir.appendingPathComponent("embedded.mobileprovision")

            guard fileManager.fileExists(atPath: p12Path.path) else {
                completion(.failure(SigningError.missingCertificate))
                return
            }
            guard fileManager.fileExists(atPath: provisionPath.path) else {
                completion(.failure(SigningError.missingProvisioningProfile))
                return
            }
            guard fileManager.fileExists(atPath: ipaUrl.path),
                  let attrs = try? fileManager.attributesOfItem(atPath: ipaUrl.path),
                  (attrs[.size] as? UInt64 ?? 0) > 0 else {
                completion(.failure(SigningError.invalidSourceFile))
                return
            }

            progress(0.2, "Подготовка окружения...")

            let outputIpaName = "signed_\(ipaUrl.lastPathComponent)"
            let outputIpaUrl = PathConfig.getDirectory(PathConfig.signedAppsFolder).appendingPathComponent(outputIpaName)

            if fileManager.fileExists(atPath: outputIpaUrl.path) {
                try? fileManager.removeItem(at: outputIpaUrl)
            }

            let password = UserDefaults.standard.string(forKey: "cert_password") ?? ""

            let localTempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("zsign_work")
            try? fileManager.createDirectory(at: localTempDir, withIntermediateDirectories: true)
            setenv("TMPDIR", localTempDir.path, 1)

            progress(0.4, "Подпись zsign...")

            // Если профиль привязан к конкретному Bundle ID, используем его, иначе оставляем исходный
            let effectiveBundleId = self.extractBundleIdFromProvision() ?? newBundleId

            var logBuffer = [CChar](repeating: 0, count: 8192)

            let result = ipaUrl.path.withCString { ipaC in
                p12Path.path.withCString { p12C in
                    password.withCString { passC in
                        provisionPath.path.withCString { provC in
                            outputIpaUrl.path.withCString { outC in
                                localTempDir.path.withCString { tempC in
                                    let bIdC = effectiveBundleId?.cString(using: .utf8)
                                    let dNameC = customDisplayName?.cString(using: .utf8)

                                    return bIdC.withOptionalCString { bPtr in
                                        dNameC.withOptionalCString { dPtr in
                                            run_zsign_direct(
                                                ipaC,
                                                p12C,
                                                passC,
                                                provC,
                                                outC,
                                                bPtr,
                                                dPtr,
                                                tempC,
                                                &logBuffer,
                                                Int32(logBuffer.count)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            try? fileManager.removeItem(at: localTempDir)

            let logString = String(cString: logBuffer).trimmingCharacters(in: .whitespacesAndNewlines)

            if result == 0 && fileManager.fileExists(atPath: outputIpaUrl.path) {
                progress(1.0, "Пакет успешно подписан")
                completion(.success(outputIpaUrl))
            } else {
                let errorDetails = logString.isEmpty ? "Код: \(result). Ошибка чтения метаданных IPA." : logString
                completion(.failure(SigningError.executionFailed(errorDetails)))
            }
        }
    }
}

private extension Optional where Wrapped == [CChar] {
    func withOptionalCString<R>(_ body: (UnsafePointer<CChar>?) -> R) -> R {
        if let self = self {
            return self.withUnsafeBufferPointer { ptr in
                body(ptr.baseAddress)
            }
        } else {
            return body(nil)
        }
    }
}
