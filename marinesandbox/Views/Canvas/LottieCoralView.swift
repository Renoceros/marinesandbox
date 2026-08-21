import Lottie
import SwiftUI

struct LottieCoralView: UIViewRepresentable {
    let coralID: UUID
    let growthProgress: Double
    let playbackProgress: Double?
    let onPlaybackCompleted: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(frame: CoralLifecycle.frame(for: growthProgress))
    }

    func makeUIView(context: Context) -> LottieAnimationView {
        let orientation = CoralLifecycle.orientation(for: coralID)
        let animationView = LottieAnimationView(
            dotLottieName: orientation.assetName,
            bundle: .main
        ) { view, error in
            guard error == nil else { return }
            context.coordinator.isLoaded = true
            view.currentFrame = context.coordinator.frame
        }
        animationView.contentMode = .scaleAspectFit
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.isAccessibilityElement = false
        return animationView
    }

    func updateUIView(_ animationView: LottieAnimationView, context: Context) {
        let frame = CoralLifecycle.frame(for: growthProgress)
        context.coordinator.frame = frame
        guard context.coordinator.isLoaded else { return }
        guard let playbackProgress else {
            animationView.currentFrame = frame
            context.coordinator.displayedFrame = frame
            return
        }
        let targetFrame = CoralLifecycle.frame(for: playbackProgress)
        guard context.coordinator.playbackTarget != targetFrame else { return }
        context.coordinator.playbackTarget = targetFrame
        animationView.play(fromFrame: context.coordinator.displayedFrame, toFrame: targetFrame) { finished in
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
