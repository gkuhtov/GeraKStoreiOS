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
    _ error_log: UnsafeMutablePointer<CChar>?,
    _ max_log_len: Int32
) -> Int32

public enum SigningError: LocalizedError {
    case missingCertificate
    case missingProvisioningProfile
    case executionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingCertificate:
            return "Файл сертификата (.p12) не найден в Настройках."
        case .missingProvisioningProfile:
            return "Профиль (.mobileprovision) не найден в Настройках."
        case .executionFailed(let details):
            return "Сбой zsign: \(details)"
        }
    }
}

public final class IPASigningEngine {
    public static let shared = IPASigningEngine()

    private init() {}

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

            progress(0.2, "Подготовка...")

            let outputIpaName = "signed_\(ipaUrl.lastPathComponent)"
            let outputIpaUrl = PathConfig.getDirectory(PathConfig.signedAppsFolder).appendingPathComponent(outputIpaName)

            if fileManager.fileExists(atPath: outputIpaUrl.path) {
                try? fileManager.removeItem(at: outputIpaUrl)
            }

            // Читаем пароль (по умолчанию пустой или "1", если не задан)
            let password = UserDefaults.standard.string(forKey: "cert_password") ?? ""

            progress(0.4, "Подпись пакета...")

            var logBuffer = [CChar](repeating: 0, count: 4096)

            let result = ipaUrl.path.withCString { ipaC in
                p12Path.path.withCString { p12C in
                    password.withCString { passC in
                        provisionPath.path.withCString { provC in
                            outputIpaUrl.path.withCString { outC in
                                let bIdC = newBundleId?.cString(using: .utf8)
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

            let logString = String(cString: logBuffer).trimmingCharacters(in: .whitespacesAndNewlines)

            if result == 0 && fileManager.fileExists(atPath: outputIpaUrl.path) {
                progress(1.0, "Пакет успешно подписан")
                completion(.success(outputIpaUrl))
            } else {
                let errorMsg = logString.isEmpty ? "Код возврата: \(result)" : logString
                completion(.failure(SigningError.executionFailed(errorMsg)))
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
