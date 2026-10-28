import Foundation
import ActivityKit

public struct InstallActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var progress: Float
        public var statusText: String
        public var stage: String

        public init(progress: Float, statusText: String, stage: String) {
            self.progress = progress
            self.statusText = statusText
            self.stage = stage
        }
    }

    public var appName: String
    public var iconUrl: String

    public init(appName: String, iconUrl: String) {
        self.appName = appName
        self.iconUrl = iconUrl
    }
}
