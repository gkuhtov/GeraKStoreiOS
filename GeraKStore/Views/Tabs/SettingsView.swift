import SwiftUI
import UniformTypeIdentifiers
import UIKit

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var theme = ThemeConfig.shared
    
    @AppStorage("cert_password") private var certPassword: String = ""
    @State private var hasP12: Bool = false
    @State private var hasMobileProvision: Bool = false
    
    @State private var showingPickerForP12 = false
    @State private var showingPickerForProvision = false
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
                                    Text((hasP12 && hasMobileProvision) ? "Сертификат готов" : "Сертификат не настроен")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    Text((hasP12 && hasMobileProvision) ? "Локальная подпись активна" : "Требуются файлы .p12 и .mobileprovision")
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

                            // Выбор .p12
                            Button(action: { showingPickerForP12 = true }) {
                                HStack {
                                    Image(systemName: "key.fill")
                                        .foregroundColor(.pink)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Сертификат (.p12)")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(hasP12 ? "Файл сохранен (cert.p12)" : "Нажмите, чтобы выбрать из Файлов")
                                            .font(.system(size: 12))
                                            .foregroundColor(hasP12 ? .green : .secondary)
                                    }
                                    Spacer()
                                    Image(systemName: hasP12 ? "checkmark.circle.fill" : "folder.badge.plus")
                                        .foregroundColor(hasP12 ? .green : .pink)
                                }
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(theme.glassMaterial))
                            }
                            .buttonStyle(.plain)

                            // Выбор .mobileprovision
                            Button(action: { showingPickerForProvision = true }) {
                                HStack {
                                    Image(systemName: "doc.badge.gearshape.fill")
                                        .foregroundColor(.pink)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Профиль (.mobileprovision)")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(hasMobileProvision ? "Файл сохранен (embedded.mobileprovision)" : "Нажмите, чтобы выбрать из Файлов")
                                            .font(.system(size: 12))
                                            .foregroundColor(hasMobileProvision ? .green : .secondary)
                                    }
                                    Spacer()
                                    Image(systemName: hasMobileProvision ? "checkmark.circle.fill" : "folder.badge.plus")
                                        .foregroundColor(hasMobileProvision ? .green : .pink)
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

                            SecureField("Пароль к p12 (оставьте пустым, если нет)", text: $certPassword)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(theme.glassMaterial))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)

                        // Очистка
                        if hasP12 || hasMobileProvision {
                            Button(role: .destructive, action: deleteCertificates) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "trash")
                                    Text("Удалить сохраненные файлы")
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
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundColor(.pink)
                }
            }
            .onAppear(perform: checkCertFiles)
            .sheet(isPresented: $showingPickerForP12) {
                SystemDocumentPicker(targetFileName: "cert.p12") { success in
                    checkCertFiles()
                    if success {
                        alertMessage = "Сертификат .p12 успешно сохранен!"
                        showAlert = true
                    }
                }
            }
            .sheet(isPresented: $showingPickerForProvision) {
                SystemDocumentPicker(targetFileName: "embedded.mobileprovision") { success in
                    checkCertFiles()
                    if success {
                        alertMessage = "Профиль .mobileprovision успешно сохранен!"
                        showAlert = true
                    }
                }
            }
            .alert("Сертификаты", isPresented: $showAlert) {
                Button("Ок", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func deleteCertificates() {
        let certsDir = PathConfig.getDirectory(PathConfig.certificatesFolder)
        try? FileManager.default.removeItem(at: certsDir.appendingPathComponent("cert.p12"))
        try? FileManager.default.removeItem(at: certsDir.appendingPathComponent("embedded.mobileprovision"))
        certPassword = ""
        checkCertFiles()
        alertMessage = "Сертификаты удалены."
        showAlert = true
    }
}

// Универсальный системный пикер для любых типов файлов
struct SystemDocumentPicker: UIViewControllerRepresentable {
    let targetFileName: String
    let onComplete: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Разрешаем открытие любых бинарных типов файлов
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item, .data, .content], asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: SystemDocumentPicker

        init(_ parent: SystemDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let pickedUrl = urls.first else {
                parent.onComplete(false)
                return
            }

            let certsDir = PathConfig.getDirectory(PathConfig.certificatesFolder)
            let destination = certsDir.appendingPathComponent(parent.targetFileName)

            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: pickedUrl, to: destination)
                parent.onComplete(true)
            } catch {
                print("Ошибка копирования файла: \(error)")
                parent.onComplete(false)
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onComplete(false)
        }
    }
}
