import Foundation

enum PathConfig {
    static let fileManager = FileManager.default

    static var cachesDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    static var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var storeCacheDirectory: URL {
        cachesDirectory.appendingPathComponent("GeraKStore", isDirectory: true)
    }

    static var downloadsDirectory: URL {
        storeCacheDirectory.appendingPathComponent("Downloads", isDirectory: true)
    }

    static var buildsDirectory: URL {
        storeCacheDirectory.appendingPathComponent("Builds", isDirectory: true)
    }

    static var certificatesDirectory: URL {
        documentsDirectory.appendingPathComponent("Certificates", isDirectory: true)
    }

    static func prepareDirectories() throws {
        for url in [storeCacheDirectory, downloadsDirectory, buildsDirectory, certificatesDirectory] {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }

        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var cacheURL = storeCacheDirectory
        try? cacheURL.setResourceValues(values)
    }
}
