import SwiftUI

public struct TodayView: View {
    @ObservedObject var theme = ThemeConfig.shared
    @State private var showSettings = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // Шапка: Дата и Аватарка профиля
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentDateFormatted.uppercased())
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.secondary)
                            Text("Сегодня")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        Button(action: {
                            HapticManager.shared.tap()
                            showSettings = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(theme.buttonGradient)
                                    .frame(width: 42, height: 42)
                                    .shadow(color: theme.rosePrimary.opacity(0.4), radius: 8)

                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    // Карточка-герой: Статус сертификата
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("СЕРТИФИКАТ АКТИВЕН", systemImage: "checkmark.seal.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(theme.roseSecondary)

                            Spacer()

                            Text("312 дней")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Text("Готов к установке и подписи")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        Text("Все приложения из каталога будут автоматически подписаны вашим профилем разработчика.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    .padding(20)
                    .liquidGlass()
                    .padding(.horizontal, 20)

                    // Секция: Удалено из App Store
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Удалено из App Store")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)

                        VStack(spacing: 12) {
                            TodayAppRow(
                                title: "СберБанк",
                                subtitle: "Сбербанк Онлайн v16.2",
                                badge: "Оригинал",
                                iconName: "rublesign.circle.fill",
                                iconColor: .green
                            )
                            TodayAppRow(
                                title: "Т-Банк",
                                subtitle: "Мобильный банк и инвестиции",
                                badge: "Оригинал",
                                iconName: "t.circle.fill",
                                iconColor: .yellow
                            )
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(theme.canvasBackground.ignoresSafeArea())
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private var currentDateFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: Date())
    }
}

private struct TodayAppRow: View {
    let title: String
    let subtitle: String
    let badge: String
    let iconName: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 54, height: 54)

                Image(systemName: iconName)
                    .font(.system(size: 28))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }

            Spacer()

            Button(action: {
                HapticManager.shared.tap()
            }) {
                Text("ЗАГРУЗИТЬ")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(ThemeConfig.shared.buttonGradient)
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .liquidGlass()
    }
}
