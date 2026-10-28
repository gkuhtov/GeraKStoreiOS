import UIKit

public final class HapticManager {
    public static let shared = HapticManager()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        lightImpact.prepare()
        mediumImpact.prepare()
        notification.prepare()
    }

    public func tap() {
        lightImpact.impactOccurred()
    }

    public func menuHold() {
        mediumImpact.impactOccurred()
    }

    public func success() {
        notification.notificationOccurred(.success)
    }

    public func error() {
        notification.notificationOccurred(.error)
    }
}
