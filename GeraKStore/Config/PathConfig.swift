import Foundation

public struct PathConfig {
    public static let certificatesFolder = "Certificates"
    public static let tempBuildFolder = "TempBuilds"
    public static let signedAppsFolder = "SignedApps"
    public static let downloadsFolder = "Downloads"

    public static func getDirectory(_ folderName: String) -> URL {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let targetDirectory = documentDirectory.appendingPathComponent(folderName, isDirectory: true)

        if !fileManager.fileExists(atPath: targetDirectory.path) {
            try? fileManager.createDirectory(at: targetDirectory, withIntermediateDirectories: true)
        }

        return targetDirectory
    }
}
