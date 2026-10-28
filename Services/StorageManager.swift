import Foundation

enum StorageManagerError: LocalizedError {
    case unableToCalculateSize

    var errorDescription: String? {
        switch self {
        case .unableToCalculateSize:
            return "Не удалось определить размер хранилища."
        }
    }
}

final class StorageManager {
    static let shared = StorageManager()

    private let fileManager = FileManager.default
    private init() {}

    func prepare() throws {
        try PathConfig.prepareDirectories()
    }

    func cacheSize() throws -> Int64 {
        let root = PathConfig.storeCacheDirectory
        guard fileManager.fileExists(atPath: root.path) else { return 0 }
        return try directorySize(at: root)
    }

    func formattedCacheSize() -> String {
        let size = (try? cacheSize()) ?? 0
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    func clearHeavyBuildCache() throws {
        try removeContents(of: PathConfig.buildsDirectory)
        try removeContents(of: PathConfig.downloadsDirectory)
    }

    func clearAllCache() throws {
        try removeContents(of: PathConfig.storeCacheDirectory)
        try PathConfig.prepareDirectories()
    }

    func makeCacheDirectory(for name: String) throws -> URL {
        let safeName = name
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let directory = PathConfig.storeCacheDirectory
            .appendingPathComponent(safeName.isEmpty ? UUID().uuidString : safeName, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func removeContents(of directory: URL) throws {
        guard fileManager.fileExists(atPath: directory.path) else { return }
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        for item in contents {
            try fileManager.removeItem(at: item)
        }
    }

    private func directorySize(at url: URL) throws -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw StorageManagerError.unableToCalculateSize
        }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
            if values.isRegularFile == true {
                total += Int64(values.fileSize ?? 0)
            }
        }
        return total
    }
}
