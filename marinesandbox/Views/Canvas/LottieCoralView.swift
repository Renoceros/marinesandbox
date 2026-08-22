import DotLottie
import DotLottiePlayer
import SwiftUI

struct LottieCoralView: UIViewRepresentable {
    let coralID: UUID
    let species: String
    let growthProgress: Double
    let playbackProgress: Double?
    let onPlaybackCompleted: () -> Void

    private static func findLottieURL(name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: "lottie") {
            return url
        }
        if let url = Bundle.main.url(forResource: name, withExtension: "lottie", subdirectory: "Lottie") {
            return url
        }
        if let url = Bundle.main.url(forResource: name, withExtension: "lottie", subdirectory: "Resources/Lottie") {
            return url
        }
        return nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            species: species,
            theme: CoralLifecycle.theme(for: coralID),
            growthProgress: growthProgress,
            onPlaybackCompleted: onPlaybackCompleted
        )
    }

    func makeUIView(context: Context) -> DotLottieAnimationView {
        let assetName = CoralLifecycle.assetName(species: species, id: coralID)
        let theme = CoralLifecycle.theme(for: coralID)
        let targetFrame = Float(CoralLifecycle.frame(for: growthProgress, species: species))

        let config = AnimationConfig(
            autoplay: false,
            loop: false,
            themeId: theme
        )

        let dotLottie: DotLottieAnimation
        if let url = Self.findLottieURL(name: assetName),
           let data = try? Data(contentsOf: url) {
            dotLottie = DotLottieAnimation(dotLottieData: data, config: config)
        } else {
            dotLottie = DotLottieAnimation(fileName: assetName, config: config)
        }

        let playerView: DotLottieAnimationView = dotLottie.view()
        playerView.contentMode = .scaleAspectFit
        playerView.isAccessibilityElement = false

        context.coordinator.dotLottie = dotLottie
        context.coordinator.targetFrame = targetFrame
        context.coordinator.theme = theme
        context.coordinator.species = species
        dotLottie.subscribe(observer: context.coordinator)

        return playerView
    }

    func updateUIView(_ uiView: DotLottieAnimationView, context: Context) {
        let targetFrame = Float(CoralLifecycle.frame(for: growthProgress, species: species))
        let theme = CoralLifecycle.theme(for: coralID)
        context.coordinator.targetFrame = targetFrame
        context.coordinator.species = species

        guard let dotLottie = context.coordinator.dotLottie else { return }

        if context.coordinator.theme != theme {
            context.coordinator.theme = theme
            _ = dotLottie.setTheme(theme)
        }

        if let playbackProgress {
            let endFrame = Float(CoralLifecycle.frame(for: playbackProgress, species: species))
            guard context.coordinator.activePlaybackEnd != endFrame else { return }
            context.coordinator.activePlaybackEnd = endFrame
            let current = dotLottie.currentFrame()
            dotLottie.setSegments(segments: (current, endFrame))
            _ = dotLottie.play()
        } else {
            context.coordinator.activePlaybackEnd = nil
            _ = dotLottie.setFrame(frame: targetFrame)
        }
    }

    final class Coordinator: NSObject, Observer {
        weak var dotLottie: DotLottieAnimation?
        var species: String
        var theme: String
        var targetFrame: Float
        var activePlaybackEnd: Float?
        let onPlaybackCompleted: () -> Void

        init(species: String, theme: String, growthProgress: Double, onPlaybackCompleted: @escaping () -> Void) {
            self.species = species
            self.theme = theme
            self.targetFrame = Float(CoralLifecycle.frame(for: growthProgress, species: species))
            self.onPlaybackCompleted = onPlaybackCompleted
            super.init()
        }

        func onLoad() {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if !self.theme.isEmpty {
                    _ = self.dotLottie?.setTheme(self.theme)
                }
                _ = self.dotLottie?.setFrame(frame: self.targetFrame)
            }
        }

        func onLoadError() {}
        func onPlay() {}
        func onPause() {}
        func onStop() {}
        func onFrame(frameNo: Float) {}
        func onRender(frameNo: Float) {}
        func onLoop(loopCount: UInt32) {}

        func onComplete() {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if self.activePlaybackEnd != nil {
                    self.activePlaybackEnd = nil
                    self.onPlaybackCompleted()
                }
            }
        }

        func onTransition(previousState: String, newState: String) {}
        func onStateEntered(enteringState: String) {}
        func onStateExit(leavingState: String) {}
        func onMessage(message: String) {}
    }
}
