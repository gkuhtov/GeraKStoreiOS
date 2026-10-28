import UIKit
import SwiftUI

public enum ScreenCutoutType {
    case dynamicIsland
    case notch
    case legacy
}

public final class DeviceManager: ObservableObject {
    public static let shared = DeviceManager()

    @Published public var modelIdentifier: String = ""
    @Published public var deviceMarketingName: String = ""
    @Published public var cutoutType: ScreenCutoutType = .dynamicIsland
    @Published public var safeAreaInsets: UIEdgeInsets = .zero

    private init() {
        self.modelIdentifier = getSystemHardwareIdentifier()
        self.deviceMarketingName = resolveMarketingName(identifier: modelIdentifier)
        self.cutoutType = resolveCutoutType()
        updateSafeArea()
    }

    public func updateSafeArea() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            self.safeAreaInsets = window.safeAreaInsets
        }
    }

    private func getSystemHardwareIdentifier() -> String {
        var size: Int = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }

    private func resolveCutoutType() -> ScreenCutoutType {
        let islandIdentifiers = [
            // iPhone 14 Pro / Pro Max
            "iPhone15,2", "iPhone15,3",
            // iPhone 15 / Plus / Pro / Pro Max
            "iPhone15,4", "iPhone15,5", "iPhone16,1", "iPhone16,2",
            // iPhone 16 / Plus / Pro / Pro Max
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4"
        ]

        if islandIdentifiers.contains(modelIdentifier) {
            return .dynamicIsland
        }

        // Если в системе окно имеет вырез сверху больше 44pt — это либо Notch, либо Island
        let topInset = safeAreaInsets.top
        if topInset >= 50 {
            return .dynamicIsland
        } else if topInset > 20 {
            return .notch
        }

        return .legacy
    }

    private func resolveMarketingName(identifier: String) -> String {
        switch identifier {
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "x86_64", "arm64": return "iOS Simulator"
        default:
            return UIDevice.current.model
        }
    }
}
