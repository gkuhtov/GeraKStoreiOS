import Foundation
import Combine

public final class CatalogService: ObservableObject {
    public static let shared = CatalogService()

    @Published public var apps: [AppItem] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    public var allApps: [AppItem] { apps }

    // Ссылка на твой актуальный GBox репозиторий
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

                guard let data = data else { return }

                // 1. Пробуем парсить как GBox repo.json
                if let gboxRepo = try? JSONDecoder().decode(GBoxRepo.self, from: data),
                   let gboxApps = gboxRepo.apps, !gboxApps.isEmpty {
                    self?.apps = gboxApps.map { AppItem(gbox: $0) }
                    print("Успешно загружено из GBox repo.json: \(self?.apps.count ?? 0) приложений")
                    return
                }

                // 2. Fallback на прямой массив AppItem
                if let flatApps = try? JSONDecoder().decode([AppItem].self, from: data) {
                    self?.apps = flatApps
                    print("Успешно загружено приложений: \(flatApps.count)")
                    return
                }

                print("Не удалось распарсить репозиторий repo.json")
            }
        }.resume()
    }
}
