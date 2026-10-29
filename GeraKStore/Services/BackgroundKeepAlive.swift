import Foundation
import AVFoundation
import UIKit

public final class BackgroundKeepAlive {
    public static let shared = BackgroundKeepAlive()

    private var audioPlayer: AVAudioPlayer?
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid

    private init() {
        setupSilentAudio()
    }

    private func setupSilentAudio() {
        // Минимальный PCM буфер тишины (WAV 44 байта)
        let wavHeader: [UInt8] = [
            0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x41, 0x56, 0x45,
            0x66, 0x6d, 0x74, 0x20, 0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
            0x44, 0xac, 0x00, 0x00, 0x88, 0x58, 0x01, 0x00, 0x02, 0x00, 0x10, 0x00,
            0x64, 0x61, 0x74, 0x61, 0x00, 0x00, 0x00, 0x00
        ]
        let data = Data(wavHeader)
        do {
            self.audioPlayer = try AVAudioPlayer(data: data)
            self.audioPlayer?.numberOfLoops = -1
            self.audioPlayer?.volume = 0.01
        } catch {
            print("Ошибка создания silent audio: \(error.localizedDescription)")
        }
    }

    public func activate() {
        // 1. Запрос стандартного системного тайм-аута фона
        self.backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "GeraKStoreOTAKeepAlive") { [weak self] in
            self?.deactivate()
        }

        // 2. Активация аудио-сессии для фоновой поддержки
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            audioPlayer?.play()
        } catch {
            print("Ошибка запуска фоновой аудио-сессии: \(error.localizedDescription)")
        }
    }

    public func deactivate() {
        audioPlayer?.stop()
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            print("Ошибка деактивации аудио-сессии: \(error.localizedDescription)")
        }

        if backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        }
    }
}
