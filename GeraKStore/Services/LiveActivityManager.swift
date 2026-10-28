import Foundation
import ActivityKit

public final class LiveActivityManager {
    public static let shared = LiveActivityManager()
    private var currentActivity: Activity<InstallActivityAttributes>? = nil

    private init() {}

    public func startActivity(appName: String, iconUrl: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = InstallActivityAttributes(appName: appName, iconUrl: iconUrl)
        let initialContentState = InstallActivityAttributes.ContentState(
            progress: 0.0,
            statusText: "Подготовка к загрузке...",
            stage: "Инициализация"
        )

        do {
            currentActivity = try Activity<InstallActivityAttributes>.request(
                attributes: attributes,
                contentState: initialContentState,
                pushType: nil
            )
        } catch {
            print("Ошибка запуска Live Activity: \(error.localizedDescription)")
        }
    }

    public func update(progress: Float, status: String, stage: String) {
        Task {
            let updatedState = InstallActivityAttributes.ContentState(
                progress: progress,
                statusText: status,
                stage: stage
            )
            await currentActivity?.update(using: updatedState)
        }
    }

    public func end() {
        Task {
            await currentActivity?.end(dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
}
