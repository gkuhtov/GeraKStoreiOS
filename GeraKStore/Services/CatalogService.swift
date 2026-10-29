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
                    self.lastStatus = "Нет ответа"
                    return
                }

                guard httpResponse.statusCode == 200 else {
                    self.lastStatus = "HTTP: \(httpResponse.statusCode)"
                    return
                }

                guard let data = data, !data.isEmpty else {
                    self.lastStatus = "repo.json пуст"
                    return
                }

                if let parsed = self.extractApps(from: data), !parsed.isEmpty {
                    self.apps = parsed
                    self.lastStatus = "Загружено: \(parsed.count) прил."
                } else {
                    if let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
                        let keys = dict.keys.joined(separator: ", ")
                        self.lastStatus = "Ключи в JSON: [\(keys)]"
                    } else {
                        self.lastStatus = "Невалидный JSON"
                    }
                }
            }
        }.resume()
    }

    private func extractApps(from data: Data) -> [AppItem]? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else {
            return nil
        }

        var candidateDicts: [[String: Any]] = []

        if let dict = jsonObject as? [String: Any] {
            // Проверяем прямое наличие массива в корне
            for key in ["apps", "app", "items", "sourceList", "list"] {
                if let arr = dict[key] as? [[String: Any]] {
                    candidateDicts.append(contentsOf: arr)
                }
            }
            
            // Если ничего не найдено, проходим по всем вложенным массивам
            if candidateDicts.isEmpty {
                for (_, value) in dict {
                    if let nested = value as? [[String: Any]] {
                        candidateDicts.append(contentsOf: nested)
                    }
                }
            }
        } else if let arr = jsonObject as? [[String: Any]] {
            candidateDicts = arr
        }

        guard !candidateDicts.isEmpty else { return nil }

        var result: [AppItem] = []

        for item in candidateDicts {
            // Название приложения
            let name = item["name"] as? String ?? item["title"] as? String ?? item["appName"] as? String
            guard let validName = name, !validName.isEmpty else { continue }

            // Bundle ID
            let bundleId = item["bundleIdentifier"] as? String
                ?? item["bundleId"] as? String
                ?? item["bundleID"] as? String
                ?? item["package"] as? String
                ?? UUID().uuidString

            let version = "\(item["version"] ?? item["appVersion"] ?? item["versionName"] ?? "1.0.0")"

            // Ссылка на скачивание
            var downloadUrlStr = item["down"] as? String
                ?? item["downloadUrl"] as? String
                ?? item["url"] as? String
                ?? item["link"] as? String
                ?? item["download"] as? String
                ?? ""

            // Вложенные версии (ESign)
            if downloadUrlStr.isEmpty, let versions = item["versions"] as? [[String: Any]], let first = versions.first {
                downloadUrlStr = first["down"] as? String ?? first["url"] as? String ?? first["link"] as? String ?? ""
            }

            guard let dlUrl = URL(string: downloadUrlStr.trimmingCharacters(in: .whitespacesAndNewlines)),
                  !downloadUrlStr.isEmpty else {
                continue
            }

            // Иконка
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

            let cat = (item["category"] as? String ?? item["type"] as? String ?? "").lowercased()
            let n = validName.lowercased()
            let isGame = cat.contains("game") || cat.contains("игр") || n.contains("game")
            let category = isGame ? "games" : "apps"
            let subcategory = item["category"] as? String ?? (isGame ? "Игры" : "Приложения")

            let typeInt = item["type"] as? Int ?? 0
            let isModded = (typeInt == 1) || n.contains("mod") || n.contains("твик")

            result.append(AppItem(
                id: bundleId,
                name: validName,
                bundleId: bundleId,
                version: version,
                minOSVersion: "15.0",
                size: sizeStr,
                category: category,
                subcategory: subcategory,
                description: desc,
                iconUrl: iconUrl,
                downloadUrl: dlUrl,
                isModded: isModded
            ))
        }

        return result
    }
}
