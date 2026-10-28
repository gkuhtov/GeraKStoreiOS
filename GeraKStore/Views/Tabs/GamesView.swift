import SwiftUI

public struct GamesView: View {
    @ObservedObject var theme = ThemeConfig.shared
    @State private var selectedGenre = "Все"
    private let genres = ["Все", "Экшен", "Гонки", "Стратегии", "РПГ", "Симуляторы", "Квесты"]

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Горизонтальный ряд чипов жанров игр
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(genres, id: \.self) { genre in
                                Button(action: {
                                    HapticManager.shared.tap()
                                    selectedGenre = genre
                                }) {
                                    Text(genre)
                                        .font(.system(size: 14, weight: selectedGenre == genre ? .bold : .medium))
                                        .foregroundColor(selectedGenre == genre ? .white : .gray)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedGenre == genre
                                            ? AnyShapeStyle(theme.buttonGradient)
                                            : AnyShapeStyle(.ultraThinMaterial)
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(selectedGenre == genre ? theme.rosePrimary.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 0.8)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)

                    // Баннер топ-новинки
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ПРОХОДИТ СЕЙЧАС")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(theme.roseSecondary)

                        Text("Asphalt Legends Unite")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        Text("Аркадный гоночный экшен с улучшенной графикой и открытыми трассами.")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                    .liquidGlass()
                    .padding(.horizontal, 20)

                    Text("Популярные игры")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
            .background(theme.canvasBackground.ignoresSafeArea())
            .navigationTitle("Игры")
        }
    }
}
