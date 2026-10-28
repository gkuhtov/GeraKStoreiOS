import SwiftUI
import UniformTypeIdentifiers

public struct CertificateManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var theme = ThemeConfig.shared
    @ObservedObject var certValidator = CertificateHealthValidator.shared

    @State private var showP12Picker = false
    @State private var showProvisionPicker = false
    @State private var p12Password = ""
    @State private var hasP12File = false
    @State private var hasProvisionFile = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                // Статус текущего сертификата
                Section(header: Text("Текущий статус").foregroundColor(.secondary)) {
                    if let cert = certValidator.currentCertInfo {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(cert.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(cert.isExpired ? "Истёк" : "\(cert.daysRemaining) дн.")
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .foregroundColor(cert.isExpired ? .red : theme.roseSecondary)
                            }

                            HStack {
                                Text("Team ID:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                Text(cert.teamIdentifier)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.white)
                            }

                            HStack {
                                Text("Устройств в профиле:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                Text("\(cert.provisionedDevices.count)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.vertical, 6)
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Сертификат еще не импортирован")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listRowBackground(Rectangle().fill(theme.glassMaterial))

                // Импорт файлов
                Section(header: Text("Импорт файлов").foregroundColor(.secondary)) {
                    Button(action: { showP12Picker = true }) {
                        HStack {
                            Label("Файл сертификата (.p12)", systemImage: "key.fill")
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: hasP12File ? "checkmark.circle.fill" : "plus.circle")
                                .foregroundColor(hasP12File ? .green : theme.rosePrimary)
                        }
                    }

                    SecureField("Пароль от .p12 (если есть)", text: $p12Password)
                        .foregroundColor(.white)

                    Button(action: { showProvisionPicker = true }) {
                        HStack {
                            Label("Профиль (.mobileprovision)", systemImage: "doc.badge.gearshape.fill")
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: hasProvisionFile ? "checkmark.circle.fill" : "plus.circle")
                                .foregroundColor(hasProvisionFile ? .green : theme.rosePrimary)
                        }
                    }
                }
                .listRowBackground(Rectangle().fill(theme.glassMaterial))

                // Сохранение
                Section {
                    Button(action: saveCertificateData) {
                        HStack {
                            Spacer()
                            Text("Сохранить сертификат")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listRowBackground(theme.buttonGradient)
            }
            .scrollContentBackground(.hidden)
            .background(theme.canvasBackground.ignoresSafeArea())
            .navigationTitle("Менеджер сертификатов")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") { dismiss() }
                        .foregroundColor(theme.rosePrimary)
                }
            }
            .sheet(isPresented: $showP12Picker) {
                DocumentPicker(allowedContentTypes: [.pkcs12]) { url in
                    importFile(url: url, destinationFolder: PathConfig.certificatesFolder, fileName: "cert.p12")
                    hasP12File = true
                }
            }
            .sheet(isPresented: $showProvisionPicker) {
                DocumentPicker(allowedContentTypes: [UTType(filenameExtension: "mobileprovision") ?? .data]) { url in
                    importFile(url: url, destinationFolder: PathConfig.certificatesFolder, fileName: "embedded.mobileprovision")
                    hasProvisionFile = true
                    certValidator.parseProfile(at: url)
                }
            }
            .alert("Сертификат", isPresented: $showAlert) {
                Button("Ок", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .onAppear(perform: checkExistingFiles)
        }
    }

    private func checkExistingFiles() {
        let certsDir = PathConfig.getDirectory(PathConfig.certificatesFolder)
        let fileManager = FileManager.default
        hasP12File = fileManager.fileExists(atPath: certsDir.appendingPathComponent("cert.p12").path)
        hasProvisionFile = fileManager.fileExists(atPath: certsDir.appendingPathComponent("embedded.mobileprovision").path)
        if let savedPassword = KeychainHelper.shared.loadString(key: StoreConfig.p12PasswordKeychainKey) {
            p12Password = savedPassword
        }
    }

    private func importFile(url: URL, destinationFolder: String, fileName: String) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        let targetDir = PathConfig.getDirectory(destinationFolder)
        let targetUrl = targetDir.appendingPathComponent(fileName)

        try? FileManager.default.removeItem(at: targetUrl)
        do {
            try FileManager.default.copyItem(at: url, to: targetUrl)
            HapticManager.shared.tap()
        } catch {
            print("Ошибка копирования файла: \(error.localizedDescription)")
        }
    }

    private func saveCertificateData() {
        HapticManager.shared.tap()
        _ = KeychainHelper.shared.saveString(key: StoreConfig.p12PasswordKeychainKey, value: p12Password)
        certValidator.validateStoredProvisionProfile()
        alertMessage = "Сертификат и профиль успешно сохранены!"
        showAlert = true
    }
}

public struct DocumentPicker: UIViewControllerRepresentable {
    let allowedContentTypes: [UTType]
    let onPick: (URL) -> Void

    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    public class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }
        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
