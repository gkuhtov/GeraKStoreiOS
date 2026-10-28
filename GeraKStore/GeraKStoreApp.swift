import SwiftUI

@main
struct GeraKStoreApp: App {
    init() {
        // Запуск локального OTA HTTP-сервера для раздачи manifest.plist и .ipa
        LocalHTTPServer.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.dark)
        }
    }
}
