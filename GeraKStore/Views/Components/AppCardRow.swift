import SwiftUI

public struct AppCardRow: View {
    public let app: AppItem
    @ObservedObject var theme = ThemeConfig.shared
    @ObservedObject var pipeline = InstallPipeline.shared

    public init(app: AppItem) {
        self.app = app
    }

    public var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: app.iconUrl) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 54, height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(app.subcategory)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    if app.isModded {
                        Text("МОД")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.pink)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.pink.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            Button(action: {
                pipeline.execute(app: app)
            }) {
                Text(pipeline.activeApp?.id == app.id ? pipeline.statusDescription : "ЗАГРУЗИТЬ")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(theme.buttonGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(theme.glassMaterial))
    }
}
