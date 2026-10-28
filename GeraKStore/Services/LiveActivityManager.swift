import Foundation
import ActivityKit

public final class LiveActivityManager {
    public static let shared = LiveActivityManager()

    private init() {}

    public func startActivity(appName: String, iconUrl: String) {
        guard #available(iOS 16.1, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = InstallActivityAttributes(appName: appName, iconUrl: iconUrl)
        let initialContentState = InstallActivityAttributes.ContentState(
            progress: 0.0,
            statusText: "Подготовка к загрузке...",
            stage: "Инициализация"
        )

        do {
            _ = try Activity<InstallActivityAttributes>.request(
                attributes: attributes,
                contentState: initialContentState,
                pushType: nil
            )
        } catch {
            print("Ошибка запуска Live Activity: \(error.localizedDescription)")
        }
    }

    public func update(progress: Float, status: String, stage: String) {
        guard #available(iOS 16.1, *) else { return }
        Task {
            let updatedState = InstallActivityAttributes.ContentState(
                progress: progress,
                statusText: status,
                stage: stage
            )
            for activity in Activity<InstallActivityAttributes>.activities {
                await activity.update(using: updatedState)
            }
        }
    }

    public func end() {
        guard #available(iOS 16.1, *) else { return }
        Task {
            for activity in Activity<InstallActivityAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }
}
