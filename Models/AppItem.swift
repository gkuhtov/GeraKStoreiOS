import Foundation

enum AppCategory: String, CaseIterable, Identifiable, Codable {
    case action = "Экшен"
    case racing = "Гонки"
    case strategy = "Стратегии"
    case arcade = "Аркады"
    case finance = "Банки"
    case photoVideo = "Фото и видео"
    case music = "Музыка"
    case social = "Соцсети"
    case utilities = "Утилиты"
    case other = "Другое"

    var id: String { rawValue }

    var isGame: Bool {
        [.action, .racing, .strategy, .arcade].contains(self)
    }
}

struct AppItem: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var subtitle: String
    var version: String
    var category: AppCategory
    var iconURL: URL?
    var downloadURL: URL?
    var fileSizeBytes: Int64?
    var popularity: Int
    var releaseDate: Date
    var isFeatured: Bool
    var isRemovedFromAppStore: Bool
    var bundleIdentifier: String?

    init(
        id: String = UUID().uuidString,
        name: String,
        subtitle: String,
        version: String = "1.0",
        category: AppCategory,
        iconURL: URL? = nil,
        downloadURL: URL? = nil,
        fileSizeBytes: Int64? = nil,
        popularity: Int = 0,
        releaseDate: Date = .now,
        isFeatured: Bool = false,
        isRemovedFromAppStore: Bool = false,
        bundleIdentifier: String? = nil
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.version = version
        self.category = category
        self.iconURL = iconURL
        self.downloadURL = downloadURL
        self.fileSizeBytes = fileSizeBytes
        self.popularity = popularity
        self.releaseDate = releaseDate
        self.isFeatured = isFeatured
        self.isRemovedFromAppStore = isRemovedFromAppStore
        self.bundleIdentifier = bundleIdentifier
    }

    var formattedSize: String {
        guard let fileSizeBytes, fileSizeBytes > 0 else { return "Размер неизвестен" }
        return ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
    }
}

enum AppSortOrder: String, CaseIterable, Identifiable {
    case date = "Сначала новые"
    case size = "По размеру"
    case popularity = "По популярности"

    var id: String { rawValue }
}
