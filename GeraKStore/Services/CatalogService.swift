import Foundation
import Combine

public final class CatalogService: ObservableObject {
    public static let shared = CatalogService()

    @Published public var apps: [AppItem] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    private let catalogUrl = URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStoreiOS/main/apps.json")!

    private init() {
        loadCatalog()
    }

    public func loadCatalog() {
        self.isLoading = true
        self.errorMessage = nil

        var request = URLRequest(url: catalogUrl)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10.0

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
                    print("Успешно загружено приложений из репозитория: \(decodedApps.count)")
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
                    id: "local_keka",
                    name: "Keka Archiver (Офлайн)",
                    bundleId: "com.aone.keka",
                    version: "1.3.1",
                    minOSVersion: "15.0",
                    size: "4.2 МБ",
                    category": "utilities",
                    subcategory: "Утилиты",
                    description: "Архиватор для проверки установки в офлайн-режиме.",
                    iconUrl: URL(string: "https://raw.githubusercontent.com/aonez/Keka/master/Images/icon.png")!,
                    downloadUrl: URL(string: "https://github.com/aonez/Keka/releases/download/v1.3.1/Keka.ipa")!,
                    isModded: false
                )
            ]
        }
    }
}
