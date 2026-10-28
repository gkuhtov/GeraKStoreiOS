import Foundation

public final class CatalogService: ObservableObject {
    public static let shared = CatalogService()

    @Published public var allApps: [AppItem] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    private init() {
        loadCatalog()
    }

    public func loadCatalog() {
        isLoading = true
        errorMessage = nil

        let url = StoreConfig.catalogURL

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.loadFallbackMockData()
                    return
                }

                guard let data = data else {
                    self?.loadFallbackMockData()
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode([AppItem].self, from: data)
                    self?.allApps = decoded
                } catch {
                    print("Ошибка декодирования apps.json: \(error)")
                    self?.loadFallbackMockData()
                }
            }
        }.resume()
    }

    /// Резервные стартовые данные на случай отсутствия сети
    private func loadFallbackMockData() {
        self.allApps = [
            AppItem(
                id: "sberbank",
                bundleId: "ru.sberbank.sberbankonline",
                name: "СберБанк",
                version: "16.2.0",
                size: "312 МБ",
                iconUrl: URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/icons/sber.png")!,
                downloadUrl: URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/ipa/sber.ipa")!,
                category: "apps",
                subcategory: "Банки",
                description: "Официальный мобильный клиент Сбербанка. Платежи, переводы по СБП, вклады и кредиты.",
                isRemovedFromAppStore: true,
                isModded: false,
                minOSVersion: "15.0",
                sha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
            ),
            AppItem(
                id: "tbank",
                bundleId: "com.tcsbank.mobile",
                name: "Т-Банк",
                version: "6.34.1",
                size: "285 МБ",
                iconUrl: URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/icons/tbank.png")!,
                downloadUrl: URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/ipa/tbank.ipa")!,
                category: "apps",
                subcategory: "Банки",
                description: "Клиент банка Т-Банк (Тинькофф). Кэшбэк, переводы, сервис брокера и связь.",
                isRemovedFromAppStore: true,
                isModded: false,
                minOSVersion: "15.0"
            ),
            AppItem(
                id: "bhtiktok",
                bundleId: "com.zhiliaoapp.musically",
                name: "TikTok BHTikTok",
                version: "36.5.0",
                size: "240 МБ",
                iconUrl: URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/icons/tiktok.png")!,
                downloadUrl: URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/ipa/tiktok.ipa")!,
                category: "apps",
                subcategory: "Соцсети",
                description: "Модифицированный клиент с твиком BHTikTok: обход ограничений региона, загрузка видео без водяных знаков и аудиофоновый режим.",
                isRemovedFromAppStore: false,
                isModded: true,
                tweakAuthor: "@BandarHL",
                minOSVersion: "15.0"
            ),
            AppItem(
                id: "asphalt_legends",
                bundleId: "com.gameloft.asphalt9",
                name: "Asphalt Legends Unite",
                version: "2.1.0",
                size: "2.8 ГБ",
                iconUrl: URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/icons/asphalt.png")!,
                downloadUrl: URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/ipa/asphalt.ipa")!,
                category: "games",
                subcategory: "Гонки",
                description: "Аркадный гоночный автосимулятор с кроссплатформенными мультиплеерными гонками.",
                isRemovedFromAppStore: false,
                isModded: false,
                minOSVersion: "16.0"
            )
        ]
    }
}
