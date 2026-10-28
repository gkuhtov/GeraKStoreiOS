import SwiftUI

public struct AppsView: View {
    @ObservedObject var theme = ThemeConfig.shared
    @State private var selectedCategory = "Все"
    private let categories = ["Все", "Банки", "Фото и видео", "Музыка", "Соцсети", "Утилиты"]

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { cat in
                                Button(action: {
                                    HapticManager.shared.tap()
                                    selectedCategory = cat
                                }) {
                                    Text(cat)
                                        .font(.system(size: 14, weight: selectedCategory == cat ? .bold : .medium))
                                        .foregroundColor(selectedCategory == cat ? .white : .gray)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedCategory == cat
                                            ? AnyShapeStyle(theme.buttonGradient)
                                            : AnyShapeStyle(.ultraThinMaterial)
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(selectedCategory == cat ? theme.rosePrimary.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 0.8)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("ПОПУЛЯРНЫЙ МОД")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(theme.roseSecondary)

                        Text("TikTok BHTikTok Plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        Text("Скачивание видео без водяного знака, смена региона и фоновое воспроизведение.")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                    .liquidGlass()
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
            .background(theme.canvasBackground.ignoresSafeArea())
            .navigationTitle("Приложения")
        }
    }
}
