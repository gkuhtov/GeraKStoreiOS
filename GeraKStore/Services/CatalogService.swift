import Foundation
import Combine

public final class CatalogService: ObservableObject {
    public static let shared = CatalogService()

    @Published public var apps: [AppItem] = []
    @Published public var isLoading: Bool = false
    @Published public var lastStatus: String = "Ожидание..."

    public var allApps: [AppItem] { apps }

    // Используем GitHub Pages — отдается мгновенно без блокировок
    private let repoUrl = URL(string: "https://gkuhtov.github.io/GeraKStore/repo.json")!
    private let fallbackUrl = URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/repo.json")!

    private init() {
        loadCatalog()
    }

    public func loadCatalog() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.lastStatus = "Загрузка каталога..."
        }

        fetchRepo(url: repoUrl) { [weak self] success in
            if !success {
                // Если Pages не ответил, пробуем fallback
                self?.fetchRepo(url: self?.fallbackUrl ?? self!.repoUrl) { _ in }
            }
        }
    }

    private func fetchRepo(url: URL, completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10.0

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else {
                    completion(false)
                    return
                }

                if let error = error {
                    self.lastStatus = "Ошибка сети: \(error.localizedDescription)"
                    self.isLoading = false
                    completion(false)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                      let data = data, !data.isEmpty else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                    self.lastStatus = "Ответ сервера: HTTP \(code)"
                    self.isLoading = false
                    completion(false)
                    return
                }

                if let parsed = self.parseGeraKStoreRepo(data: data), !parsed.isEmpty {
                    self.apps = parsed
                    self.lastStatus = "Загружено: \(parsed.count) прил."
                    self.isLoading = false
                    completion(true)
                } else {
                    self.lastStatus = "Не удалось извлечь приложения из appRepositories"
                    self.isLoading = false
                    completion(false)
                }
            }
        }.resume()
    }

    private func parseGeraKStoreRepo(data: Data) -> [AppItem]? {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as? [String: Any] else {
            return nil
        }

        guard let repositories = json["appRepositories"] as? [[String: Any]], !repositories.isEmpty else {
            return nil
        }

        var result: [AppItem] = []

        for item in repositories {
            // Название приложения
            let name = item["appName"] as? String ?? item["name"] as? String
            guard let validName = name, !validName.isEmpty else { continue }

            // Bundle ID
            let bundleId = item["bundleIdentifier"] as? String ?? item["bundleId"] as? String ?? UUID().uuidString

            // Версия
            let version = "\(item["appVersion"] ?? item["version"] ?? "1.0.0")"

            // Ссылка на IPA: в твоем файле лежит в appPackage!
            let downloadStr = item["appPackage"] as? String 
                ?? item["down"] as? String 
                ?? item["downloadUrl"] as? String 
                ?? item["url"] as? String 
                ?? ""

            guard let downloadUrl = URL(string: downloadStr.trimmingCharacters(in: .whitespacesAndNewlines)),
                  !downloadStr.isEmpty else { continue }

            // Ссылка на иконку: в твоем файле appImage или iconURL
            let iconStr = item["appImage"] as? String 
                ?? item["iconURL"] as? String 
                ?? item["icon"] as? String 
                ?? "https://gkuhtov.github.io/GeraKStore/icons/app_icon.png"

            let iconUrl = URL(string: iconStr.trimmingCharacters(in: .whitespacesAndNewlines))
                ?? URL(string: "https://gkuhtov.github.io/GeraKStore/icons/app_icon.png")!

            // Описание
            let desc = item["appDescription"] as? String 
                ?? item["description"] as? String 
                ?? item["subtitle"] as? String 
                ?? "Приложение из каталога GeraKStore."

            // Категория
            let rawCat = item["category"] as? String ?? "Приложения"
            let catLower = rawCat.lowercased()
            let isGame = catLower.contains("игры") || catLower.contains("game")
            let category = isGame ? "games" : "apps"

            let isModded = (item["appType"] as? String == "TWEAK") || (item["type"] as? Int == 1)

            result.append(AppItem(
                id: bundleId,
                name: validName,
                bundleId: bundleId,
                version: version,
                minOSVersion: "15.0",
                size: "IPA",
                category: category,
                subcategory: rawCat,
                description: desc,
                iconUrl: iconUrl,
                downloadUrl: downloadUrl,
                isModded: isModded
            ))
        }

        return result
    }
}
