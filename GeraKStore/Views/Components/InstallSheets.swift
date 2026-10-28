import SwiftUI

public struct VersionSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var theme = ThemeConfig.shared
    let app: AppItem

    public var body: some View {
        NavigationStack {
            List {
                if let versions = app.previousVersions {
                    ForEach(versions) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Версия \(record.version)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(record.releaseDate)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }

                            Text(record.changelog)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)

                            Button("Выбрать эту версию") {
                                HapticManager.shared.tap()
                                dismiss()
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(theme.rosePrimary)
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(theme.glassMaterial)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.canvasBackground.ignoresSafeArea())
            .navigationTitle("История версий")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") { dismiss() }
                        .foregroundColor(theme.rosePrimary)
                }
            }
        }
    }
}

public struct TweakInstallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var theme = ThemeConfig.shared
    let app: AppItem

    @State private var makeClone = false
    @State private var customName: String = ""
    @State private var selectedDylib: String = "Нет"

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Параметры подписи").foregroundColor(.secondary)) {
                    Toggle("Установить как дубликат (Clone)", isOn: $makeClone)

                    TextField("Кастомное имя приложения", text: $customName)
                        .foregroundColor(.white)
                }
                .listRowBackground(theme.glassMaterial)

                Section(header: Text("Внедрение dylib / твика").foregroundColor(.secondary)) {
                    HStack {
                        Text("Библиотека")
                        Spacer()
                        Text(selectedDylib)
                            .foregroundColor(.gray)
                    }
                    Button("Выбрать из Файлов...") {
                        HapticManager.shared.tap()
                    }
                    .foregroundColor(theme.rosePrimary)
                }
                .listRowBackground(theme.glassMaterial)

                Section {
                    Button(action: {
                        HapticManager.shared.success()
                        dismiss()
                        InstallPipeline.shared.execute(
                            app: app,
                            isClone: makeClone,
                            customName: customName.isEmpty ? nil : customName
                        )
                    }) {
                        HStack {
                            Spacer()
                            Text("Подписать и установить")
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
            .navigationTitle("Настройка установки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
