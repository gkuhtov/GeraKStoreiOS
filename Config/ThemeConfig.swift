import SwiftUI

enum ThemeConfig {
    static let rose = Color(red: 1.00, green: 0.20, blue: 0.58)
    static let neonPink = Color(red: 1.00, green: 0.36, blue: 0.72)
    static let violet = Color(red: 0.56, green: 0.30, blue: 1.00)
    static let backgroundTop = Color(red: 0.09, green: 0.04, blue: 0.12)
    static let backgroundBottom = Color(red: 0.02, green: 0.02, blue: 0.06)

    static let roseGradient = LinearGradient(
        colors: [rose, neonPink, violet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassStroke = LinearGradient(
        colors: [
            Color.white.opacity(0.55),
            neonPink.opacity(0.72),
            violet.opacity(0.38),
            Color.white.opacity(0.12)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct RoseGlassCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(ThemeConfig.glassStroke, lineWidth: 1)
            }
            .shadow(color: ThemeConfig.rose.opacity(0.16), radius: 18, x: 0, y: 7)
    }
}

struct OrganicBackground: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [ThemeConfig.backgroundTop, ThemeConfig.backgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(ThemeConfig.rose.opacity(0.22))
                    .frame(width: proxy.size.width * 0.72)
                    .blur(radius: 70)
                    .offset(
                        x: animate ? proxy.size.width * 0.28 : -proxy.size.width * 0.28,
                        y: animate ? -proxy.size.height * 0.20 : proxy.size.height * 0.05
                    )

                Circle()
                    .fill(ThemeConfig.violet.opacity(0.18))
                    .frame(width: proxy.size.width * 0.68)
                    .blur(radius: 80)
                    .offset(
                        x: animate ? -proxy.size.width * 0.30 : proxy.size.width * 0.24,
                        y: animate ? proxy.size.height * 0.28 : proxy.size.height * 0.08
                    )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
