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

                if let parsed = self.parseESignGBoxFormat(data: data), !parsed.isEmpty {
                    self.apps = parsed
                    self.lastStatus = "Загружено: \(parsed.count) прил."
                } else {
                    let preview = String(data: data.prefix(120), encoding: .utf8) ?? "неизвестно"
                    self.lastStatus = "Не удалось извлечь приложения из источника: \(preview)"
                }
            }
        }.resume()
    }

    private func parseESignGBoxFormat(data: Data) -> [AppItem]? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else {
            return nil
        }

        var rawList: [[String: Any]] = []

        if let dict = jsonObject as? [String: Any] {
            // В экспорте ESign/GBox приложения находятся в ключе apps
            if let apps = dict["apps"] as? [[String: Any]] {
                rawList = apps
            } else if let items = dict["items"] as? [[String: Any]] {
                rawList = items
            } else {
                // Если массив лежит внутри другого объекта
                for (_, value) in dict {
                    if let nestedArray = value as? [[String: Any]] {
                        rawList = nestedArray
                        break
                    }
                }
            }
        } else if let array = jsonObject as? [[String: Any]] {
            rawList = array
        }

        guard !rawList.isEmpty else { return nil }

        var result: [AppItem] = []

        for item in rawList {
            // Название приложения
            guard let name = item["name"] as? String ?? item["title"] as? String else { continue }

            // Bundle ID
            let bundleId = item["bundleIdentifier"] as? String 
                ?? item["bundleId"] as? String 
                ?? item["package"] as? String 
                ?? item["id"] as? String 
                ?? UUID().uuidString

            // Версия
            let version = "\(item["version"] ?? item["appVersion"] ?? "1.0.0")"

            // Ссылка на скачивание (down, downloadUrl, url, link)
            var downloadStr = item["down"] as? String 
                ?? item["downloadUrl"] as? String 
                ?? item["url"] as? String 
                ?? item["link"] as? String 
                ?? item["download"] as? String 
                ?? ""

            // Если ссылка лежит внутри объекта версий (ESign format)
            if downloadStr.isEmpty, let versions = item["versions"] as? [[String: Any]], let firstVer = versions.first {
                downloadStr = firstVer["down"] as? String ?? firstVer["url"] as? String ?? ""
            }

            guard let downloadUrl = URL(string: downloadStr.trimmingCharacters(in: .whitespacesAndNewlines)),
                  !downloadStr.isEmpty else { continue }

            // Иконка
            let iconStr = item["icon"] as? String 
                ?? item["iconUrl"] as? String 
                ?? item["artwork"] as? String 
                ?? "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/icon.png"
            let iconUrl = URL(string: iconStr.trimmingCharacters(in: .whitespacesAndNewlines)) 
                ?? URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/icon.png")!

            // Описание
            let desc = item["description"] as? String 
                ?? item["desc"] as? String 
                ?? "Приложение из личного репозитория GeraKStore."

            // Размер файла
            var sizeStr = "IPA"
            if let bytes = item["size"] as? Int64 {
                sizeStr = String(format: "%.1f МБ", Double(bytes) / (1024.0 * 1024.0))
            } else if let bytesInt = item["size"] as? Int {
                sizeStr = String(format: "%.1f МБ", Double(bytesInt) / (1024.0 * 1024.0))
            } else if let str = item["size"] as? String {
                sizeStr = str
            }

            // Категория
            let categoryField = (item["category"] as? String ?? item["type"] as? String ?? "").lowercased()
            let nameField = name.lowercased()
            let isGame = categoryField.contains("game") || categoryField.contains("игр") || nameField.contains("game")
            let category = isGame ? "games" : "apps"
            let subcategory = item["category"] as? String ?? (isGame ? "Игры" : "Приложения")

            let typeInt = item["type"] as? Int ?? 0
            let isModded = (typeInt == 1) || nameField.contains("mod") || nameField.contains("твик") || nameField.contains("bhtiktok")

            result.append(AppItem(
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
            ))
        }

        return result
    }
}
