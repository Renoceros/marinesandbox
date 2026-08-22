import SwiftUI

/// **RubblePileOverlayView: Cold-Open Dead Rubble Layer (DEC-009)**
///
/// Renders the pile of dead coral fragments covering the living survivor fragment.
/// Players flick dead rubble pieces off-screen to uncover the living coral.
struct RubblePileOverlayView: View {
    @Bindable var viewModel: SandboxViewModel
    let survivor: CoralFrag
    let seabedY: Double
    let seabedOffset: Double

    var body: some View {
        let baseX = survivor.xPos + seabedOffset
        let baseY = seabedY - survivor.yPos - 35

        ForEach(viewModel.rubblePieces) { rubble in
            if !rubble.isCleared {
                let pieceX = baseX + (rubble.isFlicked ? rubble.flickTargetOffset.x : rubble.offset.x)
                let pieceY = baseY + (rubble.isFlicked ? rubble.flickTargetOffset.y : rubble.offset.y)

                Image(rubble.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 108)
                    .rotationEffect(.degrees(rubble.rotation))
                    .opacity(rubble.isFlicked ? 0.0 : 0.95)
                    .animation(.easeOut(duration: 0.45), value: rubble.isFlicked)
                    .position(x: pieceX, y: pieceY)
                    .gesture(
                        DragGesture(minimumDistance: 3)
                            .onEnded { value in
                                let velocity = CGPoint(
                                    x: value.predictedEndLocation.x - value.location.x,
                                    y: value.predictedEndLocation.y - value.location.y
                                )
                                viewModel.flickRubble(id: rubble.id, velocity: velocity)
                            }
                    )
            }
        }
    }
}

/// Floating guided instruction banner for cold-open phases.
struct ColdOpenInstructionView: View {
    let text: String

    var body: some View {
        VStack {
            Text(text)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.65))
                        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                )
                .shadow(color: .black.opacity(0.4), radius: 6)
                .padding(.top, 56)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }
}

/// Pulsing seabed zone shown while the frag is lifted during the guided plant.
struct GuidePulseView: View {
    @Bindable var viewModel: SandboxViewModel
    let seabedY: Double
    let viewportWidth: Double

    var body: some View {
        let survivorX = viewModel.survivorFrag?.xPos ?? 200
        let target = CGPoint(x: min(survivorX + 200, Double(viewportWidth) - 80), y: seabedY - 20)
        Ellipse()
            .fill(Color.white.opacity(0.35))
            .frame(width: 140, height: 36)
            .overlay(Ellipse().stroke(.white, lineWidth: 2))
            .phaseAnimator([0.6, 1.15]) { content, phase in
                content.scaleEffect(phase).opacity(phase > 1 ? 0.6 : 1.0)
            }
            .position(x: target.x + ParallaxMetrics.seabedOffset(scrollX: viewModel.scrollX), y: target.y)
            .onTapGesture { viewModel.autoPlantSurvivor(at: CGPoint(x: target.x, y: 0)) }
    }
}
