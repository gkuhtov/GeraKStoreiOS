import Foundation
import Combine

public final class CatalogService: ObservableObject {
    public static let shared = CatalogService()

    @Published public var apps: [AppItem] = []
    @Published public var isLoading: Bool = false
    @Published public var lastStatus: String = "Ожидание..."

    public var allApps: [AppItem] { apps }

    // Основной адрес и 2 быстрых CDN-зеркала
    private let repoUrl = URL(string: "https://gkuhtov.github.io/GeraKStore/repo.json")!
    private let jsdelivrUrl = URL(string: "https://cdn.jsdelivr.net/gh/gkuhtov/GeraKStore@main/repo.json")!
    private let fallbackRawUrl = URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/repo.json")!

    private lazy var cellularSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        return URLSession(configuration: config)
    }()

    private var cacheFileUrl: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("cached_repo.json")
    }

    private init() {
        // Сначала мгновенно подгружаем сохраненный кэш, если есть
        loadCachedData()
        loadCatalog()
    }

    private func loadCachedData() {
        guard let data = try? Data(contentsOf: cacheFileUrl),
              let parsed = parseGeraKStoreRepo(data: data),
              !parsed.isEmpty else { return }
        self.apps = parsed
        self.lastStatus = "Загружено из кэша (\(parsed.count) прил.)"
    }

    public func loadCatalog() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.lastStatus = "Загрузка каталога..."
        }

        // По очереди опрашиваем GitHub Pages -> CDN jsDelivr -> Raw GitHub
        fetchRepo(url: repoUrl) { [weak self] success in
            guard let self = self else { return }
            if !success {
                self.fetchRepo(url: self.jsdelivrUrl) { secondSuccess in
                    if !secondSuccess {
                        self.fetchRepo(url: self.fallbackRawUrl) { _ in }
                    }
                }
            }
        }
    }

    private func fetchRepo(url: URL, completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 25.0
        request.setValue("GeraKStore/1.0", forHTTPHeaderField: "User-Agent")

        cellularSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else {
                    completion(false)
                    return
                }

                if let error = error {
                    // Если уже есть приложения из кэша, не сбрасываем их
                    if self.apps.isEmpty {
                        self.lastStatus = "Ошибка сети: \(error.localizedDescription)"
                    }
                    self.isLoading = false
                    completion(false)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                      let data = data, !data.isEmpty else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                    if self.apps.isEmpty {
                        self.lastStatus = "Ответ сервера: HTTP \(code)"
                    }
                    self.isLoading = false
                    completion(false)
                    return
                }

                if let parsed = self.parseGeraKStoreRepo(data: data), !parsed.isEmpty {
                    self.apps = parsed
                    self.lastStatus = "Загружено: \(parsed.count) прил."
                    self.isLoading = false
                    // Сохраняем в дисковый кэш для оффлайна
                    try? data.write(to: self.cacheFileUrl, options: .atomic)
                    completion(true)
                } else {
                    if self.apps.isEmpty {
                        self.lastStatus = "Не удалось извлечь приложения из каталога"
                    }
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
            let name = item["appName"] as? String ?? item["name"] as? String
            guard let validName = name, !validName.isEmpty else { continue }

            let bundleId = item["bundleIdentifier"] as? String ?? item["bundleId"] as? String ?? UUID().uuidString
            let version = "\(item["appVersion"] ?? item["version"] ?? "1.0.0")"

            let downloadStr = item["appPackage"] as? String
                ?? item["down"] as? String
                ?? item["downloadUrl"] as? String
                ?? item["url"] as? String
                ?? ""

            guard let downloadUrl = URL(string: downloadStr.trimmingCharacters(in: .whitespacesAndNewlines)),
                  !downloadStr.isEmpty else { continue }

            let iconStr = item["appImage"] as? String
                ?? item["iconURL"] as? String
                ?? item["icon"] as? String
                ?? "https://gkuhtov.github.io/GeraKStore/icons/app_icon.png"

            let iconUrl = URL(string: iconStr.trimmingCharacters(in: .whitespacesAndNewlines))
                ?? URL(string: "https://gkuhtov.github.io/GeraKStore/icons/app_icon.png")!

            let desc = item["appDescription"] as? String
                ?? item["description"] as? String
                ?? item["subtitle"] as? String
                ?? "Приложение из каталога GeraKStore."

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
