import SwiftUI

public final class ThemeConfig: ObservableObject {
    public static let shared = ThemeConfig()

    @Published public var canvasBackground: Color = Color(hex: "#09090D")
    @Published public var rosePrimary: Color = Color(hex: "#FF2E93")
    @Published public var roseSecondary: Color = Color(hex: "#FF75B5")
    @Published public var roseGlow: Color = Color(hex: "#FF007A").opacity(0.35)

    @Published public var glassMaterial: Material = .ultraThinMaterial
    @Published public var glassBlurRadius: CGFloat = 20.0
    @Published public var glassBorderWidth: CGFloat = 0.8
    @Published public var glassCornerRadius: CGFloat = 22.0

    public var glassBorderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.45),
                rosePrimary.opacity(0.35),
                Color.white.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [rosePrimary, roseSecondary],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

public struct LiquidGlassModifier: ViewModifier {
    @ObservedObject var theme = ThemeConfig.shared

    public func body(content: Content) -> some View {
        content
            .background(theme.glassMaterial)
            .clipShape(RoundedRectangle(cornerRadius: theme.glassCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.glassCornerRadius, style: .continuous)
                    .stroke(theme.glassBorderGradient, lineWidth: theme.glassBorderWidth)
            )
            .shadow(color: theme.roseGlow, radius: 14, x: 0, y: 6)
    }
}

public extension View {
    func liquidGlass() -> some View {
        self.modifier(LiquidGlassModifier())
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
