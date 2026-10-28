import Foundation

public struct AppItem: Identifiable, Codable, Hashable {
    public let id: String
    public let bundleId: String
    public let name: String
    public let version: String
    public let size: String
    public let iconUrl: URL
    public let downloadUrl: URL
    public let category: String
    public let subcategory: String
    public let description: String
    public let isRemovedFromAppStore: Bool
    public let isModded: Bool
    public let tweakAuthor: String?
    public let minOSVersion: String
    public let sha256: String?
    public let previousVersions: [AppVersionRecord]?
    
    public init(
        id: String,
        bundleId: String,
        name: String,
        version: String,
        size: String,
        iconUrl: URL,
        downloadUrl: URL,
        category: String,
        subcategory: String,
        description: String,
        isRemovedFromAppStore: Bool = false,
        isModded: Bool = false,
        tweakAuthor: String? = nil,
        minOSVersion: String = "15.0",
        sha256: String? = nil,
        previousVersions: [AppVersionRecord]? = nil
    ) {
        self.id = id
        self.bundleId = bundleId
        self.name = name
        self.version = version
        self.size = size
        self.iconUrl = iconUrl
        self.downloadUrl = downloadUrl
        self.category = category
        self.subcategory = subcategory
        self.description = description
        self.isRemovedFromAppStore = isRemovedFromAppStore
        self.isModded = isModded
        self.tweakAuthor = tweakAuthor
        self.minOSVersion = minOSVersion
        self.sha256 = sha256
        self.previousVersions = previousVersions
    }
}

public struct AppVersionRecord: Codable, Hashable, Identifiable {
    public var id: String { version }
    public let version: String
    public let releaseDate: String
    public let downloadUrl: URL
    public let changelog: String
}
