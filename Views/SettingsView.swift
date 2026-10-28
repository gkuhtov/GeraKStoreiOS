import SwiftUI
import LocalAuthentication
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StoreConfig.faceIDEnabledKey) private var faceIDEnabled = false
    @AppStorage(StoreConfig.smartBackgroundEnabledKey) private var smartBackgroundEnabled = true

    @State private var showingCertificatePicker = false
    @State private var showingProfilePicker = false
    @State private var showingPasswordPrompt = false
    @State private var p12Password = ""
    @State private var p12URL: URL?
    @State private var profileURL: URL?
    @State private var certificateMessage: String?
    @State private var cacheSize = "Подсчёт…"
    @State private var showingClearCacheConfirmation = false
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                OrganicBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        certificateSection
                        securitySection
                        backgroundSection
                        linksSection
                        storageSection

                        Text("Приватность: пароль сертификата не сохраняется в настройках приложения.")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.top, 4)
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                        .tint(ThemeConfig.neonPink)
                }
            }
            .fileImporter(
                isPresented: $showingCertificatePicker,
                allowedContentTypes: [UTType(filenameExtension: "p12") ?? .data],
                allowsMultipleSelection: false,
                onCompletion: handleP12Import
            )
            .fileImporter(
                isPresented: $showingProfilePicker,
                allowedContentTypes: [UTType(filenameExtension: "mobileprovision") ?? .data, .data],
                allowsMultipleSelection: false,
                onCompletion: handleProfileImport
            )
            .alert("Сертификат", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("ОК", role: .cancel) { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
            .alert("Очистить кэш?", isPresented: $showingClearCacheConfirmation) {
                Button("Отмена", role: .cancel) {}
                Button("Очистить", role: .destructive) { clearCache() }
            } message: {
                Text("Будут удалены локальные загрузки и временные сборки. Сертификаты не затрагиваются.")
            }
            .sheet(isPresented: $showingPasswordPrompt) {
                passwordSheet
                    .presentationDetents([.medium])
                    .preferredColorScheme(.dark)
            }
            .task { refreshCacheSize() }
        }
        .preferredColorScheme(.dark)
    }

    private var certificateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Менеджер сертификатов", icon: "person.badge.key.fill")

            Button {
                showingCertificatePicker = true
            } label: {
                settingsRow("Выбрать сертификат .p12", detail: p12URL?.lastPathComponent ?? "Файл не выбран", icon: "key.fill")
            }
            .buttonStyle(.plain)

            Button {
                showingProfilePicker = true
            } label: {
                settingsRow("Выбрать профиль", detail: profileURL?.lastPathComponent ?? ".mobileprovision", icon: "doc.badge.gearshape")
            }
            .buttonStyle(.plain)

            if p12URL != nil {
                Button("Проверить пароль сертификата") {
                    showingPasswordPrompt = true
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ThemeConfig.neonPink)
            }

            if let certificateMessage {
                Text(certificateMessage)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .cardStyle()
    }

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Безопасность", icon: "faceid")
            Toggle(isOn: Binding(
                get: { faceIDEnabled },
                set: { enableFaceID($0) }
            )) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Face ID")
                    Text("Запрашивать биометрию при запуске")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .tint(ThemeConfig.rose)
        }
        .cardStyle()
    }

    private var backgroundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Фоновые задачи", icon: "arrow.down.circle.fill")
            Toggle(isOn: $smartBackgroundEnabled) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Умный фон")
                    Text("Использовать разрешённое iOS время для текущих задач")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .tint(ThemeConfig.rose)
        }
        .cardStyle()
    }

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Сообщество", icon: "paperplane.fill")
            Link(destination: StoreConfig.telegramChannelURL) {
                settingsRow("Telegram-канал", detail: "Новости и обновления", icon: "megaphone.fill")
            }
            Link(destination: StoreConfig.telegramChatURL) {
                settingsRow("Telegram-чат", detail: "Обсуждение и помощь", icon: "bubble.left.and.bubble.right.fill")
            }
        }
        .cardStyle()
    }

    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Хранилище", icon: "internaldrive.fill")
            HStack {
                Label("Занято кэшем", systemImage: "externaldrive")
                Spacer()
                Text(cacheSize)
                    .foregroundStyle(.white.opacity(0.65))
                    .monospacedDigit()
            }
            Button(role: .destructive) {
                showingClearCacheConfirmation = true
            } label: {
                Label("Очистить кэш загрузок и сборок", systemImage: "trash")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .tint(ThemeConfig.neonPink)
        }
        .cardStyle()
    }

    private var passwordSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Пароль .p12")
                    .font(.title2.bold())
                SecureField("Введи пароль сертификата", text: $p12Password)
                    .textFieldStyle(.roundedBorder)
                Button("Проверить") {
                    validateP12()
                }
                .buttonStyle(.borderedProminent)
                .tint(ThemeConfig.rose)
                Spacer()
            }
            .padding(22)
            .background(ThemeConfig.backgroundBottom.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Отмена") {
                        p12Password = ""
                        showingPasswordPrompt = false
                    }
                }
            }
        }
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(ThemeConfig.neonPink)
    }

    private func settingsRow(_ title: String, detail: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(ThemeConfig.neonPink)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).foregroundStyle(.white)
                Text(detail).font(.caption).foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.35))
        }
        .contentShape(Rectangle())
    }

    private func enableFaceID(_ enabled: Bool) {
        guard enabled else {
            faceIDEnabled = false
            return
        }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            alertMessage = error?.localizedDescription ?? "Биометрическая аутентификация недоступна на этом устройстве."
            faceIDEnabled = false
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Включить защиту GeraKStore") { success, evaluationError in
            DispatchQueue.main.async {
                faceIDEnabled = success
                if !success {
                    alertMessage = evaluationError?.localizedDescription ?? "Не удалось подтвердить биометрию."
                }
            }
        }
    }

    private func handleP12Import(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            p12URL = url
            certificateMessage = "Файл выбран. Проверка пароля доступна отдельно."
        case .failure(let error):
            alertMessage = error.localizedDescription
        }
    }

    private func handleProfileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            profileURL = url
            let granted = url.startAccessingSecurityScopedResource()
            defer { if granted { url.stopAccessingSecurityScopedResource() } }
            let health = CertificateHealthValidator.inspectProvisioningProfile(at: url)
            let expiry = health.expirationDate.map {
                DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .short)
            } ?? "не определена"
            certificateMessage = "\(health.message) UDID: \(health.deviceUDIDs.count), истекает: \(expiry)"
        case .failure(let error):
            alertMessage = error.localizedDescription
        }
    }

    private func validateP12() {
        guard let p12URL else {
            alertMessage = "Сначала выбери .p12 файл."
            return
        }
        let granted = p12URL.startAccessingSecurityScopedResource()
        defer {
            if granted { p12URL.stopAccessingSecurityScopedResource() }
            p12Password = ""
            showingPasswordPrompt = false
        }
        let valid = CertificateHealthValidator.validatePKCS12(at: p12URL, password: p12Password)
        alertMessage = valid ? "PKCS#12 успешно прочитан." : "Не удалось открыть сертификат. Проверь файл и пароль."
    }

    private func refreshCacheSize() {
        cacheSize = StorageManager.shared.formattedCacheSize()
    }

    private func clearCache() {
        do {
            try StorageManager.shared.clearHeavyBuildCache()
            refreshCacheSize()
            HapticManager.success()
            alertMessage = "Кэш загрузок и сборок очищен."
        } catch {
            HapticManager.error()
            alertMessage = error.localizedDescription
        }
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(ThemeConfig.glassStroke, lineWidth: 1)
            }
    }
}
