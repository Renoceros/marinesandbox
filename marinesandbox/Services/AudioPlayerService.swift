import AVFoundation
import Foundation

/// Audio service for ambient background ocean loop and tactile interaction sound effects (DEC-035).
public final class AudioPlayerService: @unchecked Sendable {
    public static let shared = AudioPlayerService()

    private var ambientPlayer: AVAudioPlayer?
    private var sfxPlayers: [String: AVAudioPlayer] = [:]

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    private static func findAudioURL(name: String, ext: String = "wav") -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext) { return url }
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Audio") { return url }
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources/Audio") { return url }
        return nil
    }

    public func startAmbientLoop() {
        guard ambientPlayer == nil else { return }
        guard let url = Self.findAudioURL(name: "ambient_ocean_loop") else { return }
        ambientPlayer = try? AVAudioPlayer(contentsOf: url)
        ambientPlayer?.numberOfLoops = -1
        ambientPlayer?.volume = 0.30
        ambientPlayer?.prepareToPlay()
        ambientPlayer?.play()
    }

    public func stopAmbientLoop() {
        ambientPlayer?.stop()
        ambientPlayer = nil
    }

    public func playSFX(_ name: String, volume: Float = 0.8) {
        guard let url = Self.findAudioURL(name: name) else { return }
        if let player = try? AVAudioPlayer(contentsOf: url) {
            player.volume = volume
            player.prepareToPlay()
            player.play()
            sfxPlayers[name] = player
        }
    }
}
