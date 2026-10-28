import UIKit
import AVFoundation

public final class BackgroundKeepAlive {
    public static let shared = BackgroundKeepAlive()
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    private var audioPlayer: AVAudioPlayer?

    private init() {
        setupSilentAudio()
    }

    private func setupSilentAudio() {
        let emptyWavHeader: [UInt8] = [
            0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00,
            0x57, 0x41, 0x56, 0x45, 0x66, 0x6D, 0x74, 0x20,
            0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
            0x44, 0xAC, 0x00, 0x00, 0x88, 0x58, 0x01, 0x00,
            0x02, 0x00, 0x10, 0x00, 0x64, 0x61, 0x74, 0x61,
            0x00, 0x00, 0x00, 0x00
        ]
        let data = Data(emptyWavHeader)
        self.audioPlayer = try? AVAudioPlayer(data: data)
        self.audioPlayer?.numberOfLoops = -1
        self.audioPlayer?.volume = 0.01
    }

    public func activate() {
        self.backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "GeraKStoreLocalServer") { [weak self] in
            self?.deactivate()
        }
        
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        audioPlayer?.play()
    }

    public func deactivate() {
        audioPlayer?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        if backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        }
    }
}
