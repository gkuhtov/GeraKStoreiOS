import SwiftUI
import LocalAuthentication

@main
struct GeraKStoreApp: App {
    @AppStorage(StoreConfig.onboardingCompletedKey) private var onboardingCompleted = false
    @AppStorage(StoreConfig.faceIDEnabledKey) private var faceIDEnabled = false
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingOnboarding = false
    @State private var shouldOpenSettings = false
    @State private var authenticationPassed = false
    @State private var authenticationMessage: String?

    var body: some Scene {
        WindowGroup {
            Group {
                if faceIDEnabled && !authenticationPassed {
                    authenticationView
                } else if !onboardingCompleted || showingOnboarding {
                    OnboardingView(
                        onImportCertificate: {
                            onboardingCompleted = true
                            shouldOpenSettings = true
                            showingOnboarding = false
                        },
                        onBrowseCatalog: {
                            onboardingCompleted = true
                            showingOnboarding = false
                        }
                    )
                } else {
                    RootTabView(openSettingsOnAppear: shouldOpenSettings)
                }
            }
            .task {
                try? StorageManager.shared.prepare()
                if !onboardingCompleted {
                    showingOnboarding = true
                }
                if faceIDEnabled {
                    authenticate()
                } else {
                    authenticationPassed = true
                }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active && faceIDEnabled {
                    authenticationPassed = false
                    authenticate()
                }
            }
        }
    }

    private var authenticationView: some View {
        ZStack {
            OrganicBackground()
            VStack(spacing: 18) {
                Image(systemName: "faceid")
                    .font(.system(size: 64))
                    .foregroundStyle(ThemeConfig.roseGradient)
                Text("GeraKStore заблокирован")
                    .font(.title2.bold())
                Text(authenticationMessage ?? "Подтверди личность, чтобы продолжить.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                Button("Повторить проверку") { authenticate() }
                    .buttonStyle(.borderedProminent)
                    .tint(ThemeConfig.rose)
            }
            .padding(28)
        }
        .preferredColorScheme(.dark)
    }

    private func authenticate() {
        let context = LAContext()
        context.localizedCancelTitle = "Отмена"
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            authenticationMessage = error?.localizedDescription ?? "Защита устройства недоступна."
            authenticationPassed = false
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Разблокировать GeraKStore") { success, evaluationError in
            DispatchQueue.main.async {
                authenticationPassed = success
                authenticationMessage = success ? nil : (evaluationError?.localizedDescription ?? "Проверка не пройдена.")
            }
        }
    }
}

