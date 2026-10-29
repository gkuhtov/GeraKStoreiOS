import Foundation

public enum SigningError: LocalizedError {
    case missingCertificate
    case missingProvisioningProfile
    case zsignBinaryNotFound
    case executionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingCertificate:
            return "Сертификат (.p12) не найден. Добавьте его в Настройках."
        case .missingProvisioningProfile:
            return "Профиль (.mobileprovision) не найден. Добавьте его в Настройках."
        case .zsignBinaryNotFound:
            return "Движок zsign не найден в бандле."
        case .executionFailed(let msg):
            return "Ошибка подписи: \(msg)"
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

            guard let zsignBinary = Bundle.main.path(forResource: "zsign", ofType: nil) ?? 
                  Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("zsign").path,
                  fileManager.fileExists(atPath: zsignBinary) else {
                completion(.failure(SigningError.zsignBinaryNotFound))
                return
            }

            progress(0.2, "Подготовка к подписи...")

            let outputIpaName = "signed_\(ipaUrl.lastPathComponent)"
            let outputIpaUrl = PathConfig.getDirectory(PathConfig.signedAppsFolder).appendingPathComponent(outputIpaName)

            if fileManager.fileExists(atPath: outputIpaUrl.path) {
                try? fileManager.removeItem(at: outputIpaUrl)
            }

            var arguments: [String] = [
                zsignBinary,
                "-k", p12Path.path,
                "-m", provisionPath.path,
                "-o", outputIpaUrl.path
            ]

            // Пароль от p12 из настроек
            let password = UserDefaults.standard.string(forKey: "cert_password") ?? ""
            if !password.isEmpty {
                arguments.append(contentsOf: ["-p", password])
            }

            if let bundleId = newBundleId, !bundleId.isEmpty {
                arguments.append(contentsOf: ["-b", bundleId])
            }

            if let displayName = customDisplayName, !displayName.isEmpty {
                arguments.append(contentsOf: ["-n", displayName])
            }

            arguments.append(ipaUrl.path)

            progress(0.5, "Выполнение zsign...")

            let success = self.runExecutable(args: arguments)
            if success && fileManager.fileExists(atPath: outputIpaUrl.path) {
                progress(1.0, "Пакет успешно подписан")
                completion(.success(outputIpaUrl))
            } else {
                completion(.failure(SigningError.executionFailed("Сбой выполнения zsign")))
            }
        }
    }

    private func runExecutable(args: [String]) -> Bool {
        guard let binary = args.first else { return false }
        
        var pid: pid_t = 0
        let cArgs = args.map { strdup($0) } + [nil]
        defer {
            for ptr in cArgs where ptr != nil { free(ptr) }
        }

        let result = posix_spawn(&pid, binary, nil, nil, cArgs, nil)
        guard result == 0 else { return false }

        var status: Int32 = 0
        waitpid(pid, &status, 0)
        return status == 0
    }
}
