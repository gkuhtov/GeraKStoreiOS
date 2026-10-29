import Foundation
import Combine

public final class CatalogService: ObservableObject {
    public static let shared = CatalogService()

    @Published public var apps: [AppItem] = []
    @Published public var isLoading: Bool = false
    @Published public var lastStatus: String = "Ожидание..."

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
        request.timeoutInterval = 15.0

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.lastStatus = "Ошибка сети: \(error.localizedDescription)"
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
                    self.lastStatus = "Файл repo.json пуст"
                    return
                }

                if let parsed = self.deepSearchApps(data: data), !parsed.isEmpty {
                    self.apps = parsed
                    self.lastStatus = "Загружено: \(parsed.count) прил."
                } else {
                    let preview = String(data: data.prefix(160), encoding: .utf8) ?? ""
                    self.lastStatus = "Ключи в JSON не найдены: \(preview)"
                }
            }
        }.resume()
    }

    private func deepSearchApps(data: Data) -> [AppItem]? {
        guard let root = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else {
            return nil
        }

        var candidates: [[String: Any]] = []

        // Рекурсивный поиск массива со словарями приложений
        func inspect(element: Any) {
            if let dict = element as? [String: Any] {
                // Если этот словарь сам похож на карточку приложения
                if (dict["name"] != nil || dict["title"] != nil) &&
                   (dict["down"] != nil || dict["downloadUrl"] != nil || dict["url"] != nil || dict["link"] != nil || dict["versions"] != nil) {
                    candidates.append(dict)
                    return
                }
                for (_, value) in dict {
                    inspect(element: value)
                }
            } else if let array = element as? [Any] {
                for item in array {
                    inspect(element: item)
                }
            }
        }

        inspect(element: root)
        guard !candidates.isEmpty else { return nil }

        return candidates.compactMap { item -> AppItem? in
            guard let name = item["name"] as? String ?? item["title"] as? String else { return nil }

            let bundleId = item["bundleIdentifier"] as? String 
                ?? item["bundleId"] as? String 
                ?? item["package"] as? String 
                ?? item["id"] as? String 
                ?? UUID().uuidString

            let version = "\(item["version"] ?? item["appVersion"] ?? "1.0.0")"

            var downloadStr = item["down"] as? String 
                ?? item["downloadUrl"] as? String 
                ?? item["url"] as? String 
                ?? item["link"] as? String 
                ?? item["download"] as? String 
                ?? ""

            // Поддержка вложенного списка версий ESign
            if downloadStr.isEmpty, let versions = item["versions"] as? [[String: Any]], let firstVer = versions.first {
                downloadStr = firstVer["down"] as? String ?? firstVer["url"] as? String ?? firstVer["link"] as? String ?? ""
            }

            guard let downloadUrl = URL(string: downloadStr.trimmingCharacters(in: .whitespacesAndNewlines)),
                  !downloadStr.isEmpty else { return nil }

            let iconStr = item["icon"] as? String 
                ?? item["iconUrl"] as? String 
                ?? item["artwork"] as? String 
                ?? "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/icon.png"
            let iconUrl = URL(string: iconStr.trimmingCharacters(in: .whitespacesAndNewlines)) 
                ?? URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/icon.png")!

            let desc = item["description"] as? String 
                ?? item["desc"] as? String 
                ?? "Приложение из личного репозитория GeraKStore."

            var sizeStr = "IPA"
            if let bytes = item["size"] as? Int64 {
                sizeStr = String(format: "%.1f МБ", Double(bytes) / (1024.0 * 1024.0))
            } else if let bytesInt = item["size"] as? Int {
                sizeStr = String(format: "%.1f МБ", Double(bytesInt) / (1024.0 * 1024.0))
            } else if let str = item["size"] as? String {
                sizeStr = str
            }

            let categoryField = (item["category"] as? String ?? item["type"] as? String ?? "").lowercased()
            let nameField = name.lowercased()
            let isGame = categoryField.contains("game") || categoryField.contains("игр") || nameField.contains("game")
            let category = isGame ? "games" : "apps"
            let subcategory = item["category"] as? String ?? (isGame ? "Игры" : "Приложения")

            let typeInt = item["type"] as? Int ?? 0
            let isModded = (typeInt == 1) || nameField.contains("mod") || nameField.contains("твик") || nameField.contains("bhtiktok")

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
