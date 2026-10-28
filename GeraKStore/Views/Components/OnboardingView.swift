import SwiftUI

public struct OnboardingView: View {
    @ObservedObject var theme = ThemeConfig.shared
    @Binding var isPresented: Bool
    
    var onImportCertificate: () -> Void
    var onExploreCatalog: () -> Void

    @State private var appearLogo = false
    @State private var appearCard1 = false
    @State private var appearCard2 = false
    @State private var glowPhase: CGFloat = 0.0

    public init(
        isPresented: Binding<Bool>,
        onImportCertificate: @escaping () -> Void,
        onExploreCatalog: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self.onImportCertificate = onImportCertificate
        self.onExploreCatalog = onExploreCatalog
    }

    public var body: some View {
        ZStack {
            theme.canvasBackground.ignoresSafeArea()
            
            Circle()
                .fill(theme.rosePrimary.opacity(0.25))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -80, y: -180 + glowPhase)
            
            Circle()
                .fill(theme.roseSecondary.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: 100, y: 150 - glowPhase)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(theme.buttonGradient)
                            .frame(width: 88, height: 88)
                            .shadow(color: theme.rosePrimary.opacity(0.5), radius: 20, y: 10)

                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 42))
                            .foregroundColor(.white)
                    }

                    Text("GeraKStore")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Ваш персональный хаб приложений")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .opacity(appearLogo ? 1.0 : 0.0)
                .offset(y: appearLogo ? 0 : 20)

                Spacer()

                VStack(spacing: 16) {
                    Button(action: {
                        HapticManager.shared.tap()
                        onImportCertificate()
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(theme.buttonGradient)
                                    .frame(width: 48, height: 48)
                                    .shadow(color: theme.rosePrimary.opacity(0.4), radius: 8)

                                Image(systemName: "key.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Импорт сертификата")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Добавьте .p12 и профиль для мгновенной подписи и установки")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(theme.rosePrimary)
                        }
                        .padding(18)
                        .liquidGlass()
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .opacity(appearCard1 ? 1.0 : 0.0)
                    .offset(y: appearCard1 ? 0 : 30)

                    Button(action: {
                        HapticManager.shared.tap()
                        onExploreCatalog()
                        withAnimation(.spring()) {
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(width: 48, height: 48)

                                Image(systemName: "square.grid.2x2.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.8))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Перейти в каталог")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)

                                Text("Полистать подборки и моды (установка станет доступна позже)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        .padding(18)
                        .background(.ultraThinMaterial.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: theme.glassCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.glassCornerRadius, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .opacity(appearCard2 ? 1.0 : 0.0)
                    .offset(y: appearCard2 ? 0 : 30)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearLogo = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                appearCard1 = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.35)) {
                appearCard2 = true
            }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                glowPhase = 30.0
            }
        }
    }
}

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
