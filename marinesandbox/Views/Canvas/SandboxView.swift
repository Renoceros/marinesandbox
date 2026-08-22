import Combine
import SwiftData
import SwiftUI

/// **SandboxView: The Coral Screen (workflow §2.3)**
///
/// Everything happens here: the guided first plant, the care loop (brush, hand,
/// plant), threats, growth, and Fast Forward — layered over the parallax world.
/// Gesture routing follows DEC-026: coral views carry their own gestures.
///
/// Modularized into specialized canvas views:
/// - `RubblePileOverlayView.swift`: Cold-open rubble pile, instructions, guide pulse.
/// - `SandboxToolOverlayView.swift`: Sponge bubble tool, speed controls, reset button.
/// - `SandboxPestView.swift`: Pest overlay, tap/flick animations, crawling snails, tooltip.
/// - `DiagnosticCardView.swift`: 5-year reflection card modal.
///
struct SandboxView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SandboxViewModel?

    /// Endpoints of the in-flight brush stroke (screen space), for segment clearing.
    @State private var lastBrushPoint: CGPoint?

    /// A pest being flung off-screen (drives throw animation, then removal).
    @State private var flyingPest: FlyingPest?

    /// Pests currently executing their vertical squash & fade-out smush animation (DEC-034).
    @State private var smushedPestIDs: Set<String> = []

    /// The live tick timer (DEC-031): advances the reef by one refresh slice while visible.
    private let ticker = Timer.publish(every: SandboxViewModel.tickInterval, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            if let viewModel {
                let seabedY = geometry.size.height
                ZStack(alignment: .bottomLeading) {
                    ParallaxScrollView(scrollX: Binding(
                        get: { viewModel.scrollX },
                        set: { viewModel.scrollX = $0 }
                    ))

                    entityLayer(viewModel: viewModel, seabedY: seabedY)

                    if !PlaygroundMode.isEnabled {
                        if viewModel.guidedPlantPhase == .awaitingRubbleClear {
                            ColdOpenInstructionView(text: "Flick away the dead rubble to uncover the living coral!")
                        } else if viewModel.guidedPlantPhase == .awaitingFragTap {
                            ColdOpenInstructionView(text: "Drag the living fragment onto the sand to plant it!")
                        } else if viewModel.guidedPlantPhase == .awaitingPlant {
                            GuidePulseView(viewModel: viewModel, seabedY: seabedY, viewportWidth: geometry.size.width)
                            ColdOpenInstructionView(text: "Drop the fragment onto the seabed!")
                        }

                        SandboxToolOverlayView(
                            viewModel: viewModel,
                            seabedY: seabedY,
                            lastBrushPoint: $lastBrushPoint
                        )

                        if viewModel.showPestTooltip {
                            PestTooltipView(viewModel: viewModel)
                        }

                        if viewModel.pendingDiagnostic != nil {
                            DiagnosticCardView(viewModel: viewModel)
                        }
                    }
                }
                .onReceive(ticker) { _ in
                    guard !PlaygroundMode.isEnabled else { return }
                    viewModel.tickLive()
                }
                .onAppear {
                    AudioPlayerService.shared.startAmbientLoop()
                    viewModel.updateFieldGeometry(
                        viewportWidth: geometry.size.width,
                        viewportHeight: geometry.size.height
                    )
                    if PlaygroundMode.isEnabled {
                        viewModel.resetToSinglePlaygroundFrag()
                    }
                }
                .onDisappear {
                    AudioPlayerService.shared.stopAmbientLoop()
                }
                .onChange(of: geometry.size) { _, size in
                    viewModel.updateFieldGeometry(
                        viewportWidth: size.width,
                        viewportHeight: size.height
                    )
                }
            } else {
                Color(hex: "3BAFED").ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
        .defersSystemGestures(on: .bottom)
        .onAppear {
            AudioPlayerService.shared.startAmbientLoop()
            if viewModel == nil {
                let vm = SandboxViewModel(modelContext: modelContext)
                vm.loadOrCreateCanvas()
                viewModel = vm
            }
        }
    }

    // MARK: - Entity Layer

    @ViewBuilder
    private func entityLayer(viewModel: SandboxViewModel, seabedY: Double) -> some View {
        let seabedOffset = ParallaxMetrics.seabedOffset(scrollX: viewModel.scrollX)

        ForEach(viewModel.canvas?.coralFrags ?? [], id: \.id) { frag in
            let coral = frag.snapshotForInteraction
            let footprint = CoralGeometry.footprint(for: coral)
            let isSurvivor = frag.id == viewModel.survivorFrag?.id
            let assetName = footprint.assetName
            let isLifted = viewModel.liftedFragID == frag.id
            let screenX = (isLifted ? viewModel.liftedFragPosition.x : coral.xPos) + seabedOffset
            let baseY = seabedY - (isLifted ? viewModel.liftedFragPosition.y : coral.yPos)

            ZStack {
                coralArtView(viewModel: viewModel, frag: frag, assetName: assetName, footprint: footprint)
                    .scaleEffect(isLifted ? 1.15 : 1.0)
                    .shadow(color: isLifted ? .white.opacity(0.6) : .clear, radius: 12)
                    .shadow(color: (isSurvivor && viewModel.isSurvivorUncovered) ? .yellow.opacity(0.9) : .clear, radius: 20)

                if !frag.isDead && frag.algaePercentage > 0.02 {
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color(red: 0.35, green: 0.3, blue: 0.15).opacity(frag.algaePercentage * 0.5))
                        .frame(width: footprint.size.width, height: footprint.size.height)
                        .blur(radius: 14)
                        .allowsHitTesting(false)
                }

                ForEach(Array(frag.activePredators.enumerated()), id: \.offset) { index, _ in
                    PestOverlayView(
                        viewModel: viewModel,
                        frag: frag,
                        index: index,
                        footprint: footprint,
                        flyingPest: $flyingPest,
                        smushedPestIDs: $smushedPestIDs
                    )
                }
            }
            .frame(width: footprint.size.width, height: footprint.size.height)
            .contentShape(Rectangle())
            .position(x: screenX, y: baseY - footprint.size.height / 2)
            .gesture(
                // Corals are movable only during the fragment/baby stage (growthProgress < 0.25) when uncovered.
                // Once a coral matures to the toddler phase (growthProgress >= 0.25), it becomes firmly rooted and cannot be moved!
                (isSurvivor && !viewModel.isSurvivorUncovered) || (frag.growthProgress >= 0.25)
                    ? nil
                    : coralDrag(viewModel: viewModel, frag: frag, seabedY: seabedY)
            )
            .onTapGesture {
                if !isSurvivor || viewModel.isSurvivorUncovered {
                    handleCoralTap(viewModel: viewModel, frag: frag)
                }
            }
        }

        // Crawling Snails sliding from off-screen margins (DEC-034)
        ForEach(viewModel.crawlingSnails) { snail in
            CrawlingSnailView(
                viewModel: viewModel,
                snail: snail,
                seabedY: seabedY,
                seabedOffset: seabedOffset
            )
        }

        if let canvas = viewModel.canvas, !canvas.guidedPlantDone, let survivor = viewModel.survivorFrag {
            RubblePileOverlayView(
                viewModel: viewModel,
                survivor: survivor,
                seabedY: seabedY,
                seabedOffset: seabedOffset
            )
        }
    }

    @ViewBuilder
    private func coralArtView(
        viewModel: SandboxViewModel,
        frag: CoralFrag,
        assetName: String,
        footprint: CoralGeometry.Footprint
    ) -> some View {
        if frag.isDead {
            Image(assetName)
                .resizable()
                .frame(width: footprint.size.width, height: footprint.size.height)
                .saturation(0)
                .opacity(0.5)
        } else {
            let isUnplanted = (frag.id == viewModel.survivorFrag?.id && viewModel.guidedPlantPhase != .done)
            let progress = isUnplanted ? 0.0 : frag.growthProgress

            LottieCoralView(
                coralID: frag.id,
                growthProgress: progress,
                playbackProgress: viewModel.lottiePlaybackTargets[frag.id],
                onPlaybackCompleted: { viewModel.completeLottiePlayback(for: frag.id) }
            )
            .frame(width: footprint.size.width, height: footprint.size.height)
        }
    }

    // MARK: - Gestures

    private func coralDrag(viewModel: SandboxViewModel, frag: CoralFrag, seabedY: Double) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                let seabedOffset = ParallaxMetrics.seabedOffset(scrollX: viewModel.scrollX)
                let canvas = CGPoint(x: value.location.x - seabedOffset, y: value.location.y)

                if viewModel.liftedFragID != frag.id {
                    withAnimation(.spring(response: 0.3, dampingFraction: Physics.sinkDamping)) {
                        viewModel.liftFrag(id: frag.id)
                    }
                }
                if viewModel.liftedFragID == frag.id {
                    viewModel.dragLiftedFrag(to: CGPoint(x: canvas.x, y: liftHeight(of: value.location.y, seabedY: seabedY)))
                } else if viewModel.selectedTool == .sponge {
                    if let last = lastBrushPoint {
                        _ = viewModel.applyBrushSegment(from: last, to: canvas, seabedY: seabedY)
                    }
                    lastBrushPoint = canvas
                }
            }
            .onEnded { _ in
                if viewModel.liftedFragID == frag.id {
                    let dropHeight = viewModel.liftedFragPosition.y
                    let resting = viewModel.restingHeight(
                        forDropHeight: dropHeight,
                        atX: viewModel.liftedFragPosition.x
                    )
                    let response = Physics.sinkResponse(
                        fallHeight: dropHeight - resting,
                        viewportHeight: seabedY
                    )

                    withAnimation(.spring(response: response, dampingFraction: Physics.sinkDamping)) {
                        viewModel.dragLiftedFrag(
                            to: CGPoint(x: viewModel.liftedFragPosition.x, y: resting)
                        )
                    }

                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + Physics.sinkSettleDuration(response: response)
                    ) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.plantLiftedFrag()
                        }
                    }
                }
                lastBrushPoint = nil
            }
    }

    private func liftHeight(of screenY: Double, seabedY: Double) -> Double {
        max(0, seabedY - screenY)
    }

    private func handleCoralTap(viewModel: SandboxViewModel, frag: CoralFrag) {
        if viewModel.guidedPlantPhase == .awaitingFragTap, frag.id == viewModel.survivorFrag?.id {
            viewModel.liftSurvivorFrag()
        }
    }
}

#Preview {
    SandboxView()
        .modelContainer(for: [UserProfile.self, ReefCanvas.self, CoralFrag.self, NGOConfig.self], inMemory: true)
}
