import Foundation
import Combine

public final class CatalogService: ObservableObject {
    public static let shared = CatalogService()

    @Published public var apps: [AppItem] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    public var allApps: [AppItem] { apps }

    private let repoUrl = URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/repo.json")!

    private init() {
        loadCatalog()
    }

    public func loadCatalog() {
        self.isLoading = true
        self.errorMessage = nil

        var request = URLRequest(url: repoUrl)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 15.0

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    print("Ошибка запроса каталога: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    print("Пустой ответ от сервера")
                    return
                }

                // Парсим JSON через гибкий словарь без строгого Decodable
                if let parsedApps = self?.parseDynamicJson(data: data), !parsedApps.isEmpty {
                    self?.apps = parsedApps
                    print("Успешно распарсено приложений: \(parsedApps.count)")
                } else {
                    print("Не удалось извлечь приложения из repo.json")
                }
            }
        }.resume()
    }

    private func parseDynamicJson(data: Data) -> [AppItem]? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }

        var rawList: [[String: Any]] = []

        if let dict = jsonObject as? [String: Any] {
            // Проверяем распространенные ключи GBox/ESign репозиториев
            if let appsArray = dict["apps"] as? [[String: Any]] {
                rawList = appsArray
            } else if let itemsArray = dict["items"] as? [[String: Any]] {
                rawList = itemsArray
            } else if let listArray = dict["list"] as? [[String: Any]] {
                rawList = listArray
            }
        } else if let array = jsonObject as? [[String: Any]] {
            rawList = array
        }

        guard !rawList.isEmpty else { return nil }

        return rawList.compactMap { item -> AppItem? in
            guard let name = item["name"] as? String else { return nil }

            let bundleId = item["bundleIdentifier"] as? String ?? item["bundleId"] as? String ?? UUID().uuidString
            let version = "\(item["version"] ?? "1.0.0")"
            let desc = item["description"] as? String ?? "Приложение из каталога GeraKStore."

            // Определение ссылки на загрузку
            let downStr = item["down"] as? String ?? item["downloadUrl"] as? String ?? item["url"] as? String ?? ""
            guard let downloadUrl = URL(string: downStr) else { return nil }

            // Определение иконки
            let iconStr = item["icon"] as? String ?? item["iconUrl"] as? String ?? "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/icon.png"
            let iconUrl = URL(string: iconStr) ?? URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/icon.png")!

            // Определение размера
            var sizeStr = "IPA"
            if let sizeBytes = item["size"] as? Int64 {
                sizeStr = String(format: "%.1f МБ", Double(sizeBytes) / 1024.0 / 1024.0)
            } else if let sizeInt = item["size"] as? Int {
                sizeStr = String(format: "%.1f МБ", Double(sizeInt) / 1024.0 / 1024.0)
            } else if let sizeText = item["size"] as? String {
                sizeStr = sizeText
            }

            // Определение типа и категории
            let categoryRaw = (item["category"] as? String ?? "").lowercased()
            let nameRaw = name.lowercased()
            let isGame = categoryRaw.contains("game") || categoryRaw.contains("игр") || nameRaw.contains("game")
            let category = isGame ? "games" : "apps"
            let subcategory = item["category"] as? String ?? (isGame ? "Игры" : "Приложения")

            let typeInt = item["type"] as? Int ?? 0
            let isModded = (typeInt == 1) || nameRaw.contains("mod") || nameRaw.contains("hack")

            return AppItem(
                id: bundleId,
                name: name,
                bundleId: bundleId,
                version: version,
                minOSVersion: "15.0",
                size: sizeStr,
                category: category,
                subcategory: subcategory,
                description: desc,
                iconUrl: iconUrl,
                downloadUrl: downloadUrl,
                isModded: isModded
            )
        }
    }
}
