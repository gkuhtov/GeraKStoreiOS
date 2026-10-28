import SwiftUI
import WidgetKit
import ActivityKit

public struct InstallActivityWidget: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: InstallActivityAttributes.self) { context in
            // Виджет на экране блокировки (Lock Screen)
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color(hex: "#FF2E93"), Color(hex: "#FF75B5")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 44, height: 44)

                        Image(systemName: "arrow.down.app.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.appName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(context.state.statusText)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Text("\(Int(context.state.progress * 100))%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#FF75B5"))
                }

                // Шкала прогресса
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 6)

                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color(hex: "#FF2E93"), Color(hex: "#FF75B5")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: max(0, min(geo.size.width * CGFloat(context.state.progress), geo.size.width)), height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .activityBackgroundTint(Color(hex: "#09090D").opacity(0.85))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Развернутый вид Dynamic Island (Expanded)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(Color(hex: "#FF2E93"))
                            .font(.system(size: 20))
                        
                        Text(context.attributes.appName)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                    }
                    .padding(.leading, 8)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#FF75B5"))
                        .padding(.trailing, 8)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.statusText)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)

                        ProgressView(value: Double(context.state.progress))
                            .tint(Color(hex: "#FF2E93"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                // Свернутый компактный вид: Иконка слева
                Image(systemName: "arrow.down.app.fill")
                    .foregroundColor(Color(hex: "#FF2E93"))
                    .font(.system(size: 13))
                    .padding(.leading, 4)
            } compactTrailing: {
                // Свернутый компактный вид: Процент справа
                Text("\(Int(context.state.progress * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#FF75B5"))
                    .padding(.trailing, 4)
            } minimal: {
                // Минимальный вид, если остров занят несколькими процессами
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(Color(hex: "#FF2E93"))
            }
        }
    }
}
