import Foundation

public struct StoreConfig {
    public static var repositoryOwner = "gkuhtov"
    public static var repositoryName = "GeraKStore"
    public static var branchName = "main"
    public static var catalogFileName = "apps.json"

    public static var catalogURL: URL {
        URL(string: "https://raw.githubusercontent.com/\(repositoryOwner)/\(repositoryName)/\(branchName)/\(catalogFileName)")!
    }

    public static var localServerPort: UInt16 = 8080
    public static var localServerHost = "127.0.0.1"
    
    public static let p12KeychainKey = "com.gerakstore.cert.p12"
    public static let p12PasswordKeychainKey = "com.gerakstore.cert.password"
    public static let provisionPathKey = "com.gerakstore.cert.provision"
}
