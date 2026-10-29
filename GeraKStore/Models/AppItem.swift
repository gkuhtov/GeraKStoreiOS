import Foundation

public struct GBoxRepo: Codable {
    public let name: String?
    public let identifier: String?
    public let apps: [GBoxAppItem]?
}

public struct GBoxAppItem: Codable {
    public let name: String
    public let bundleIdentifier: String?
    public let version: String?
    public let versionDate: String?
    public let size: Int64?
    public let down: String
    public let icon: String?
    public let description: String?
    public let type: Int?
}

public struct AppItem: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let bundleId: String
    public let version: String
    public let minOSVersion: String
    public let size: String
    public let category: String
    public let subcategory: String
    public let description: String
    public let iconUrl: URL
    public let downloadUrl: URL
    public let isModded: Bool

    public init(gbox: GBoxAppItem) {
        self.id = gbox.bundleIdentifier ?? UUID().uuidString
        self.name = gbox.name
        self.bundleId = gbox.bundleIdentifier ?? "com.unknown.app"
        self.version = gbox.version ?? "1.0.0"
        self.minOSVersion = "15.0"
        
        if let bytes = gbox.size, bytes > 0 {
            let mb = Double(bytes) / 1024.0 / 1024.0
            self.size = String(format: "%.1f МБ", mb)
        } else {
            self.size = "IPA"
        }
        
        self.category = "apps"
        self.subcategory = "GBox Репозиторий"
        self.description = gbox.description ?? "Приложение из личного репозитория GeraKStore."
        
        let rawIcon = gbox.icon ?? "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/icon.png"
        self.iconUrl = URL(string: rawIcon) ?? URL(string: "https://raw.githubusercontent.com/gkuhtov/GeraKStore/main/icon.png")!
        
        self.downloadUrl = URL(string: gbox.down) ?? URL(string: "https://example.com")!
        self.isModded = (gbox.type == 1)
    }

    public init(
        id: String,
        name: String,
        bundleId: String,
        version: String,
        minOSVersion: String = "15.0",
        size: String,
        category: String,
        subcategory: String,
        description: String,
        iconUrl: URL,
        downloadUrl: URL,
        isModded: Bool = false
    ) {
        self.id = id
        self.name = name
        self.bundleId = bundleId
        self.version = version
        self.minOSVersion = minOSVersion
        self.size = size
        self.category = category
        self.subcategory = subcategory
        self.description = description
        self.iconUrl = iconUrl
        self.downloadUrl = downloadUrl
        self.isModded = isModded
    }
}
