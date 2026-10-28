import Foundation

enum StoreConfig {
    static let appName = "GeraKStore"
    static let minimumIOSVersion = "16.0"
    static let telegramChannelURL = URL(string: "https://t.me/")!
    static let telegramChatURL = URL(string: "https://t.me/")!
    static let onboardingCompletedKey = "gerakstore.onboarding.completed"
    static let faceIDEnabledKey = "gerakstore.security.faceid.enabled"
    static let smartBackgroundEnabledKey = "gerakstore.background.smart.enabled"
    static let searchHistoryKey = "gerakstore.search.history"
    static let maxSearchHistoryItems = 12
    static let cacheWarningBytes: Int64 = 1_000_000_000
}
