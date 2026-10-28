import Foundation
import UIKit

/// Coordinates short, legitimate background work. iOS may suspend the app when the
/// task expires; this service intentionally does not play silent audio to evade that limit.
final class BackgroundKeepAlive {
    static let shared = BackgroundKeepAlive()

    private var taskIdentifier: UIBackgroundTaskIdentifier = .invalid
    private let lock = NSLock()

    private init() {}

    @MainActor
    func beginTask(name: String = "GeraKStore.Transfer") {
        lock.lock()
        let alreadyRunning = taskIdentifier != .invalid
        lock.unlock()
        guard !alreadyRunning else { return }

        let identifier = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
            self?.endTask()
        }

        lock.lock()
        taskIdentifier = identifier
        lock.unlock()

        if identifier == .invalid {
            return
        }
    }

    @MainActor
    func endTask() {
        lock.lock()
        let identifier = taskIdentifier
        taskIdentifier = .invalid
        lock.unlock()

        guard identifier != .invalid else { return }
        UIApplication.shared.endBackgroundTask(identifier)
    }
}
