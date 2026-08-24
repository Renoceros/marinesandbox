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
        let candidateNames = [
            name,
            name.replacingOccurrences(of: "sparkles", with: "sparkle"),
            name.replacingOccurrences(of: "sparkle", with: "sparkles")
        ]
        for cand in candidateNames {
            if let url = Bundle.main.url(forResource: cand, withExtension: ext) { return url }
            if let url = Bundle.main.url(forResource: cand, withExtension: ext, subdirectory: "Audio") { return url }
            if let url = Bundle.main.url(forResource: cand, withExtension: ext, subdirectory: "Resources/Audio") { return url }
        }
        return nil
    }

    public func startAmbientLoop() {
        guard ambientPlayer == nil else { return }
        guard let url = Self.findAudioURL(name: "ambient_ocean_loop") else { return }
        ambientPlayer = try? AVAudioPlayer(contentsOf: url)
        ambientPlayer?.numberOfLoops = -1
        ambientPlayer?.volume = 0.22
        ambientPlayer?.prepareToPlay()
        ambientPlayer?.play()
    }

    public func stopAmbientLoop() {
        ambientPlayer?.stop()
        ambientPlayer = nil
    }

    public func playSFX(_ name: String, volume: Float? = nil) {
        guard let url = Self.findAudioURL(name: name) else { return }
        let defaultVolume: Float = {
            switch name {
            case "brush_swipe": return 0.50
            case "frag_lift": return 0.70
            case "frag_plant": return 0.85
            case "sparkle_clean", "sparkles_clean": return 0.75
            case "pest_smush": return 0.80
            case "pest_flick": return 0.75
            case "pest_splash": return 0.65
            case "tool_switch": return 0.60
            case "threat_warning": return 0.60
            case "plant_reject": return 0.70
            default: return 0.75
            }
        }()

        if let player = try? AVAudioPlayer(contentsOf: url) {
            player.volume = volume ?? defaultVolume
            player.prepareToPlay()
            player.play()
            sfxPlayers[name] = player
        }
    }
}
