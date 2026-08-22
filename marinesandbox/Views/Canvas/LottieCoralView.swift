import DotLottie
import DotLottiePlayer
import SwiftUI

struct LottieCoralView: UIViewRepresentable {
    let coralID: UUID
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
            growthProgress: growthProgress,
            onPlaybackCompleted: onPlaybackCompleted
        )
    }

    func makeUIView(context: Context) -> DotLottieAnimationView {
        let orientation = CoralLifecycle.orientation(for: coralID)
        let theme = CoralLifecycle.theme(for: coralID)
        let targetFrame = Float(CoralLifecycle.frame(for: growthProgress))

        let config = AnimationConfig(
            autoplay: false,
            loop: false,
            themeId: theme
        )

        let dotLottie: DotLottieAnimation
        if let url = Self.findLottieURL(name: orientation.assetName),
           let data = try? Data(contentsOf: url) {
            dotLottie = DotLottieAnimation(dotLottieData: data, config: config)
        } else {
            dotLottie = DotLottieAnimation(fileName: orientation.assetName, config: config)
        }

        let playerView: DotLottieAnimationView = dotLottie.view()
        playerView.contentMode = .scaleAspectFit
        playerView.isAccessibilityElement = false

        context.coordinator.dotLottie = dotLottie
        context.coordinator.targetFrame = targetFrame
        dotLottie.subscribe(observer: context.coordinator)

        return playerView
    }

    func updateUIView(_ uiView: DotLottieAnimationView, context: Context) {
        let targetFrame = Float(CoralLifecycle.frame(for: growthProgress))
        context.coordinator.targetFrame = targetFrame

        guard let dotLottie = context.coordinator.dotLottie else { return }

        if let playbackProgress {
            let endFrame = Float(CoralLifecycle.frame(for: playbackProgress))
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
        var targetFrame: Float
        var activePlaybackEnd: Float?
        let onPlaybackCompleted: () -> Void

        init(growthProgress: Double, onPlaybackCompleted: @escaping () -> Void) {
            self.targetFrame = Float(CoralLifecycle.frame(for: growthProgress))
            self.onPlaybackCompleted = onPlaybackCompleted
            super.init()
        }

        func onLoad() {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
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
