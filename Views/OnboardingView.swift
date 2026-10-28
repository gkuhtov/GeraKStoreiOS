import SwiftUI

struct OnboardingView: View {
    let onImportCertificate: () -> Void
    let onBrowseCatalog: () -> Void

    var body: some View {
        ZStack {
            OrganicBackground()

            VStack(spacing: 26) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(ThemeConfig.rose.opacity(0.18))
                        .frame(width: 132, height: 132)
                        .blur(radius: 18)
                    Image(systemName: "app.gift.fill")
                        .font(.system(size: 62, weight: .medium))
                        .foregroundStyle(ThemeConfig.roseGradient)
                        .shadow(color: ThemeConfig.rose.opacity(0.55), radius: 20)
                }

                VStack(spacing: 10) {
                    Text("GeraKStore")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Твой каталог. Твои правила.")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Импортируй сертификат для подготовки совместимых пакетов или сначала загляни в каталог.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.62))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }

                Spacer()

                VStack(spacing: 14) {
                    Button(action: onImportCertificate) {
                        HStack(spacing: 14) {
                            Image(systemName: "person.badge.key.fill")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Импорт сертификата").font(.headline)
                                Text(".p12 и provisioning profile").font(.caption).opacity(0.75)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.doc")
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(ThemeConfig.roseGradient.opacity(0.28), in: RoundedRectangle(cornerRadius: 22))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(ThemeConfig.glassStroke, lineWidth: 1))
                    .padding(16)

                    Button(action: onBrowseCatalog) {
                        HStack {
                            Image(systemName: "square.grid.2x2.fill")
                            Text("Перейти в каталог")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(18)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.18), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                Text("Продолжая, ты подтверждаешь, что используешь только те приложения и сертификаты, на которые имеешь право.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.48))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 22)
        }
        .preferredColorScheme(.dark)
    }
}
