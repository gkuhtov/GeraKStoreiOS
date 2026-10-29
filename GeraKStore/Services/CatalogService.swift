import Foundation
import Combine

public final class CatalogService: ObservableObject {
    public static let shared = CatalogService()

    @Published public var apps: [AppItem] = []
    @Published public var isLoading: Bool = false
    @Published public var lastStatus: String = "Ожидание загрузки..."

    public var allApps: [AppItem] { apps }

    private let repoUrl = URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/repo.json")!

    private init() {
        loadCatalog()
    }

    public func loadCatalog() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.lastStatus = "Загрузка каталога..."
        }

        var request = URLRequest(url: repoUrl)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10.0

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.lastStatus = "Ошибка сети: \(error.localizedDescription)"
                    print(self.lastStatus)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.lastStatus = "Нет ответа от сервера"
                    return
                }

                guard httpResponse.statusCode == 200 else {
                    self.lastStatus = "Ошибка HTTP: \(httpResponse.statusCode)"
                    return
                }

                guard let data = data, !data.isEmpty else {
                    self.lastStatus = "repo.json пуст"
                    return
                }

                if let parsed = self.parseDynamicJson(data: data), !parsed.isEmpty {
                    self.apps = parsed
                    self.lastStatus = "Загружено: \(parsed.count) прил."
                    print("Успех: загружено \(parsed.count) приложений")
                } else {
                    self.lastStatus = "Не удалось распознать формат JSON"
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
            let desc = item["description"] as? String ?? "Приложение из личного репозитория GeraKStore."

            let downStr = item["down"] as? String ?? item["downloadUrl"] as? String ?? item["url"] as? String ?? ""
            guard let downloadUrl = URL(string: downStr) else { return nil }

            let iconStr = item["icon"] as? String ?? item["iconUrl"] as? String ?? "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/icon.png"
            let iconUrl = URL(string: iconStr) ?? URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/icon.png")!

            var sizeStr = "IPA"
            if let sizeBytes = item["size"] as? Int64 {
                sizeStr = String(format: "%.1f МБ", Double(sizeBytes) / 1024.0 / 1024.0)
            } else if let sizeInt = item["size"] as? Int {
                sizeStr = String(format: "%.1f МБ", Double(sizeInt) / 1024.0 / 1024.0)
            } else if let sizeText = item["size"] as? String {
                sizeStr = sizeText
            }

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
