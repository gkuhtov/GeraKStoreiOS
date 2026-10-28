import SwiftUI

public struct AppItemRow: View {
    @ObservedObject var theme = ThemeConfig.shared
    let app: AppItem

    public var body: some View {
        NavigationLink(destination: ProductDetailView(app: app)) {
            HStack(spacing: 14) {
                AsyncImage(url: app.iconUrl) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    }
                }
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.6)
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(app.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(app.subcategory)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)

                        if app.isModded {
                            Text("МОД")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(theme.rosePrimary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(theme.rosePrimary.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                Button(action: {
                    HapticManager.shared.tap()
                    InstallPipeline.shared.execute(app: app)
                }) {
                    Text("ЗАГРУЗИТЬ")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(theme.buttonGradient)
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(14)
            .liquidGlass()
        }
        .buttonStyle(PlainButtonStyle())
    }
}
