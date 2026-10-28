import Foundation

public final class StorageManager: ObservableObject {
    public static let shared = StorageManager()
    @Published public var cacheSizeFormatted: String = "0 МБ"

    private init() {
        calculateCacheSize()
    }

    public func calculateCacheSize() {
        DispatchQueue.global(qos: .utility).async {
            let tempDir = PathConfig.getDirectory(PathConfig.tempCacheFolder)
            let downloadsDir = PathConfig.getDirectory(PathConfig.ipaDownloadsFolder)
            let signedDir = PathConfig.getDirectory(PathConfig.signedOutputFolder)
            
            let totalBytes = self.directorySize(url: tempDir) + 
                             self.directorySize(url: downloadsDir) + 
                             self.directorySize(url: signedDir)
            
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useMB, .useGB]
            formatter.countStyle = .file
            let formatted = formatter.string(fromByteCount: totalBytes)
            
            DispatchQueue.main.async {
                self.cacheSizeFormatted = formatted
            }
        }
    }

    public func purgeTempBuilds() {
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            let tempDir = PathConfig.getDirectory(PathConfig.tempCacheFolder)
            let signedDir = PathConfig.getDirectory(PathConfig.signedOutputFolder)
            
            [tempDir, signedDir].forEach { folder in
                if let files = try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
                    for file in files {
                        try? fileManager.removeItem(at: file)
                    }
                }
            }
            self.calculateCacheSize()
        }
    }

    private func directorySize(url: URL) -> Int64 {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        return files.reduce(0) { total, fileUrl in
            let values = try? fileUrl.resourceValues(forKeys: [.fileSizeKey])
            return total + Int64(values?.fileSize ?? 0)
        }
    }
}
