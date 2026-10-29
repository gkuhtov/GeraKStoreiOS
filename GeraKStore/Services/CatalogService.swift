import Foundation
import Combine

public final class CatalogService: ObservableObject {
    public static let shared = CatalogService()

    @Published public var apps: [AppItem] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    public var allApps: [AppItem] {
        return apps
    }

    // Твой репозиторий GeraKStore
    private let catalogUrl = URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/apps.json")!

    private init() {
        loadCatalog()
    }

    public func loadCatalog() {
        self.isLoading = true
        self.errorMessage = nil

        var request = URLRequest(url: catalogUrl)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 15.0

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Ошибка запроса каталога: \(error.localizedDescription)")
                    self?.loadLocalFallback()
                    return
                }

                guard let data = data else {
                    self?.loadLocalFallback()
                    return
                }

                do {
                    let decodedApps = try JSONDecoder().decode([AppItem].self, from: data)
                    self?.apps = decodedApps
                    print("Успешно загружено приложений из GeraKStore: \(decodedApps.count)")
                } catch {
                    print("Ошибка декодирования apps.json: \(error)")
                    self?.loadLocalFallback()
                }
            }
        }.resume()
    }

    private func loadLocalFallback() {
        if self.apps.isEmpty {
            self.apps = [
                AppItem(
                    id: "app_gerakstore_fallback",
                    name: "GeraKStore",
                    bundleId: "com.gkuhtov.gerakstore",
                    version: "1.0.0",
                    minOSVersion: "16.1",
                    size: "2.5 МБ",
                    category: "apps",
                    subcategory: "Системные",
                    description: "Каталог GeraKStore.",
                    iconUrl: URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/icon.png")!,
                    downloadUrl: URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/apps.json")!,
                    isModded: false
                )
            ]
        }
    }
}
