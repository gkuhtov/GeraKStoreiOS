import SwiftUI

public struct AppItemRow: View {
    public let app: AppItem
    public let onInstall: () -> Void

    @ObservedObject private var pipeline = InstallPipeline.shared

    public init(app: AppItem, onInstall: @escaping () -> Void) {
        self.app = app
        self.onInstall = onInstall
    }

    private var isCurrentAppActive: Bool {
        pipeline.activeApp?.bundleId == app.bundleId
    }

    public var body: some View {
        HStack(spacing: 16) {
            RemoteImageView(url: app.iconUrl, cornerRadius: 14)

            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(app.subcategory)
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.6))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onInstall) {
                Text(isCurrentAppActive ? (pipeline.statusDescription.isEmpty ? "..." : pipeline.statusDescription) : "ЗАГРУЗИТЬ")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(red: 235/255, green: 40/255, blue: 110/255))
                    .clipShape(Capsule())
            }
            .disabled(isCurrentAppActive)
        }
        .padding(.vertical, 8)
    }
}
