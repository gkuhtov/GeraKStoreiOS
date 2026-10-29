import SwiftUI
import UniformTypeIdentifiers

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var theme = ThemeConfig.shared
    
    @AppStorage("cert_password") private var certPassword: String = ""
    @State private var hasP12: Bool = false
    @State private var hasMobileProvision: Bool = false
    
    @State private var isImportingP12: Bool = false
    @State private var isImportingProvision: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    public init() {}

    private func checkCertFiles() {
        let certsDir = PathConfig.getDirectory(PathConfig.certificatesFolder)
        let p12Path = certsDir.appendingPathComponent("cert.p12").path
        let provPath = certsDir.appendingPathComponent("embedded.mobileprovision").path
        hasP12 = FileManager.default.fileExists(atPath: p12Path)
        hasMobileProvision = FileManager.default.fileExists(atPath: provPath)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.canvasBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Блок текущего статуса
                        VStack(alignment: .leading, spacing: 12) {
                            Text("СТАТУС ПОДПИСИ")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)

                            HStack {
                                Image(systemName: (hasP12 && hasMobileProvision) ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor((hasP12 && hasMobileProvision) ? .pink : .orange)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text((hasP12 && hasMobileProvision) ? "Сертификат установлен" : "Сертификат не настроен")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    Text((hasP12 && hasMobileProvision) ? "Локальная подпись готова к работе" : "Требуются файлы .p12 и .mobileprovision")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(theme.glassMaterial))
                        }
                        .padding(.horizontal, 16)

                        // Блок импорта файлов
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ФАЙЛЫ РАЗРАБОТЧИКА")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)

                            // Кнопка импорта .p12
                            Button(action: { isImportingP12 = true }) {
                                HStack {
                                    Image(systemName: "key.fill")
                                        .foregroundColor(.pink)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Сертификат (.p12)")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(hasP12 ? "Импортирован (cert.p12)" : "Нажмите для выбора файла")
                                            .font(.system(size: 12))
                                            .foregroundColor(hasP12 ? .green : .secondary)
                                    }
                                    Spacer()
                                    Image(systemName: hasP12 ? "checkmark.circle.fill" : "arrow.up.doc")
                                        .foregroundColor(hasP12 ? .green : .secondary)
                                }
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(theme.glassMaterial))
                            }
                            .buttonStyle(.plain)

                            // Кнопка импорта .mobileprovision
                            Button(action: { isImportingProvision = true }) {
                                HStack {
                                    Image(systemName: "doc.badge.gearshape.fill")
                                        .foregroundColor(.pink)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Профиль (.mobileprovision)")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(hasMobileProvision ? "Импортирован (embedded.mobileprovision)" : "Нажмите для выбора файла")
                                            .font(.system(size: 12))
                                            .foregroundColor(hasMobileProvision ? .green : .secondary)
                                    }
                                    Spacer()
                                    Image(systemName: hasMobileProvision ? "checkmark.circle.fill" : "arrow.up.doc")
                                        .foregroundColor(hasMobileProvision ? .green : .secondary)
                                }
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(theme.glassMaterial))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)

                        // Поле ввода пароля сертификата
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ПАРОЛЬ СЕРТИФИКАТА")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)

                            SecureField("Введите пароль от .p12 (если есть)", text: $certPassword)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(theme.glassMaterial))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)

                        // Кнопка сброса сертификатов
                        if hasP12 || hasMobileProvision {
                            Button(role: .destructive, action: deleteCertificates) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "trash")
                                    Text("Удалить установленный сертификат")
                                    Spacer()
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.red.opacity(0.1)))
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Настройки сертификата")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.pink)
                }
            }
            .onAppear(perform: checkCertFiles)
            .fileImporter(
                isPresented: $isImportingP12,
                allowedContentTypes: [.data, .item],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result, targetName: "cert.p12")
            }
            .fileImporter(
                isPresented: $isImportingProvision,
                allowedContentTypes: [.data, .item],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result, targetName: "embedded.mobileprovision")
            }
            .alert("Сертификаты", isPresented: $showAlert) {
                Button("Ок", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func handleImport(result: Result<[URL], Error>, targetName: String) {
        do {
            guard let selectedUrl = try result.get().first else { return }
            
            if selectedUrl.startAccessingSecurityScopedResource() {
                defer { selectedUrl.stopAccessingSecurityScopedResource() }
                
                let certsDir = PathConfig.getDirectory(PathConfig.certificatesFolder)
                let destinationUrl = certsDir.appendingPathComponent(targetName)

                if FileManager.default.fileExists(atPath: destinationUrl.path) {
                    try FileManager.default.removeItem(at: destinationUrl)
                }
                
                try FileManager.default.copyItem(at: selectedUrl, to: destinationUrl)
                checkCertFiles()
                
                alertMessage = "Файл \(targetName) успешно импортирован!"
                showAlert = true
            }
        } catch {
            alertMessage = "Ошибка при сохранении файла: \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func deleteCertificates() {
        let certsDir = PathConfig.getDirectory(PathConfig.certificatesFolder)
        let p12Url = certsDir.appendingPathComponent("cert.p12")
        let provUrl = certsDir.appendingPathComponent("embedded.mobileprovision")

        try? FileManager.default.removeItem(at: p12Url)
        try? FileManager.default.removeItem(at: provUrl)
        certPassword = ""
        checkCertFiles()
        
        alertMessage = "Сертификаты и профиль успешно удалены."
        showAlert = true
    }
}
