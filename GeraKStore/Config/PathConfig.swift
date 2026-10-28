import Foundation

public struct PathConfig {
    public static var rootDirectoryName = "GeraKStoreData"
    public static var ipaDownloadsFolder = "Downloads"
    public static var signedOutputFolder = "SignedPackages"
    public static var certificatesFolder = "UserCerts"
    public static var dylibInjectionsFolder = "Tweaks"
    public static var tempCacheFolder = "TempBuild"

    public static func getDirectory(_ folderName: String) -> URL {
        let fileManager = FileManager.default
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let target = base.appendingPathComponent(rootDirectoryName).appendingPathComponent(folderName)
        
        if !fileManager.fileExists(atPath: target.path) {
            try? fileManager.createDirectory(at: target, withIntermediateDirectories: true)
        }
        return target
    }
}
