import Foundation

public struct VersionRecord: Codable, Identifiable, Hashable {
    public var id: String { version }
    public let version: String
    public let releaseDate: String
    public let downloadUrl: URL
    public let changelog: String

    public init(version: String, releaseDate: String, downloadUrl: URL, changelog: String) {
        self.version = version
        self.releaseDate = releaseDate
        self.downloadUrl = downloadUrl
        self.changelog = changelog
    }
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
    public let tweakAuthor: String?
    public let sha256: String?
    public let previousVersions: [VersionRecord]?

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
        isModded: Bool = false,
        tweakAuthor: String? = nil,
        sha256: String? = nil,
        previousVersions: [VersionRecord]? = nil
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
        self.tweakAuthor = tweakAuthor
        self.sha256 = sha256
        self.previousVersions = previousVersions
    }
}
