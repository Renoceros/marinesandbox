import Lottie
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
        Coordinator(frame: CoralLifecycle.frame(for: growthProgress))
    }

    func makeUIView(context: Context) -> LottieAnimationView {
        let orientation = CoralLifecycle.orientation(for: coralID)
        let animationView = LottieAnimationView()
        animationView.contentMode = .scaleAspectFit
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.isAccessibilityElement = false

        if let url = Self.findLottieURL(name: orientation.assetName) {
            DotLottieFile.loadedFrom(url: url) { result in
                guard case .success(let file) = result else { return }
                animationView.loadAnimation(from: file)
                context.coordinator.isLoaded = true
                let targetFrame = context.coordinator.frame
                animationView.currentFrame = AnimationFrameTime(targetFrame)
                context.coordinator.displayedFrame = targetFrame
            }
        } else {
            DotLottieFile.named(orientation.assetName, bundle: .main) { result in
                guard case .success(let file) = result else { return }
                animationView.loadAnimation(from: file)
                context.coordinator.isLoaded = true
                let targetFrame = context.coordinator.frame
                animationView.currentFrame = AnimationFrameTime(targetFrame)
                context.coordinator.displayedFrame = targetFrame
            }
        }

        return animationView
    }

    func updateUIView(_ animationView: LottieAnimationView, context: Context) {
        let frame = CoralLifecycle.frame(for: growthProgress)
        context.coordinator.frame = frame
        guard context.coordinator.isLoaded else { return }
        guard let playbackProgress else {
            animationView.currentFrame = AnimationFrameTime(frame)
            context.coordinator.displayedFrame = frame
            return
        }
        let targetFrame = CoralLifecycle.frame(for: playbackProgress)
        guard context.coordinator.playbackTarget != targetFrame else { return }
        context.coordinator.playbackTarget = targetFrame
        animationView.play(
            fromFrame: AnimationFrameTime(context.coordinator.displayedFrame),
            toFrame: AnimationFrameTime(targetFrame)
        ) { finished in
            guard finished else { return }
            context.coordinator.displayedFrame = targetFrame
            context.coordinator.playbackTarget = nil
            onPlaybackCompleted()
        }
    }

    final class Coordinator {
        var frame: Double
        var displayedFrame: Double
        var playbackTarget: Double?
        var isLoaded = false

        init(frame: Double) {
            self.frame = frame
            displayedFrame = frame
        }
    }
}
