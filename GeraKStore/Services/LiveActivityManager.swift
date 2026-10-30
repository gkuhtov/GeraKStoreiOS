import Foundation
import ActivityKit

public final class LiveActivityManager {
    public static let shared = LiveActivityManager()

    private init() {}

    public func startLiveActivity(appName: String, iconUrl: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = InstallActivityAttributes(appName: appName, iconUrl: iconUrl)
        let initialContentState = InstallActivityAttributes.ContentState(progress: 0.0, statusMessage: "Подготовка...")

        do {
            let content = ActivityContent(state: initialContentState, staleDate: nil)
            _ = try Activity<InstallActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("Ошибка запуска Live Activity: \(error.localizedDescription)")
        }
    }

    public func updateLiveActivity(progress: Double, statusMessage: String) {
        Task {
            let updatedState = InstallActivityAttributes.ContentState(
                progress: progress,
                statusMessage: statusMessage
            )
            let content = ActivityContent(state: updatedState, staleDate: nil)
            for activity in Activity<InstallActivityAttributes>.activities {
                await activity.update(content)
            }
        }
    }

    public func endLiveActivity(statusMessage: String) {
        Task {
            let finalState = InstallActivityAttributes.ContentState(
                progress: 1.0,
                statusMessage: statusMessage
            )
            let content = ActivityContent(state: finalState, staleDate: nil)
            for activity in Activity<InstallActivityAttributes>.activities {
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }
    }
}
