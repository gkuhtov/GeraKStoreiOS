import SwiftUI
import LocalAuthentication

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var theme = ThemeConfig.shared
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject var device = DeviceManager.shared

    @AppStorage("useFaceID") private var useFaceID: Bool = false
    @AppStorage("smartBackground") private var smartBackground: Bool = true
    @AppStorage("debugMode") private var debugMode: Bool = false

    @State private var showClearCacheAlert = false
    @State private var userUDID: String = "00008140-001878943C09801C"

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(theme.buttonGradient)
                                .frame(width: 36, height: 36)
                            Image(systemName: "iphone.gen3")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.deviceMarketingName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("UDID: \(userUDID)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16))
                            .foregroundColor(theme.rosePrimary)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Rectangle().fill(theme.glassMaterial))

                Section(header: Text("Настройки").font(.footnote).foregroundColor(.secondary)) {
                    Toggle(isOn: $useFaceID) {
                        Label {
                            Text("Face ID")
                                .font(.system(size: 15))
                        } icon: {
                            Image(systemName: "faceid")
                                .foregroundColor(theme.rosePrimary)
                        }
                    }
                    .onChange(of: useFaceID) { enabled in
                        if enabled { authenticateWithBiometrics() }
                    }

                    Link(destination: URL(string: "https://t.me/gkuhtov")!) {
                        SettingRow(icon: "play.circle.fill", title: "Видео инструкция", color: .blue)
                    }

                    Link(destination: URL(string: "https://t.me/gkuhtov")!) {
                        SettingRow(icon: "paperplane.fill", title: "Канал в Telegram", color: .cyan)
                    }
                }
                .listRowBackground(Rectangle().fill(theme.glassMaterial))

                Section(header: Text("Хранилище и о приложении").font(.footnote).foregroundColor(.secondary)) {
                    Button(action: { showClearCacheAlert = true }) {
                        HStack {
                            Label {
                                Text("Очистить кэш")
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)
                            } icon: {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                            }
                            Spacer()
                            Text(storage.cacheSizeFormatted)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Label {
                            Text("О GeraKStore")
                                .font(.system(size: 15))
                        } icon: {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("v1.0.0 (Build 1)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .listRowBackground(Rectangle().fill(theme.glassMaterial))
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(theme.canvasBackground.ignoresSafeArea())
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundColor(theme.rosePrimary)
                }
            }
            .alert("Очистить кэш?", isPresented: $showClearCacheAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Очистить", role: .destructive) {
                    HapticManager.shared.tap()
                    storage.purgeTempBuilds()
                }
            } message: {
                Text("Будут удалены все временные файлы, загруженные архивы и собранные пакеты подписи.")
            }
        }
    }

    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Подтвердите вход в GeraKStore") { success, _ in
                DispatchQueue.main.async {
                    if !success { self.useFaceID = false }
                }
            }
        } else {
            self.useFaceID = false
        }
    }
}

private struct SettingRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack {
            Label {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
    }
}
