import Combine
import SwiftUI
import SwiftData

/// **SandboxView: The Coral Screen (workflow §2.3)**
///
/// Everything happens here: the guided first plant, the care loop (brush, hand,
/// plant), threats, growth, and Fast Forward — layered over the parallax world.
/// Gesture routing follows DEC-026: coral views carry their own gestures, so a
/// touch that starts on a coral belongs to the active tool and never reaches the
/// pan gesture; a drag on empty water pans the world.
///
/// Mid-fi: algae and pests render as simple overlays until the DEC-019 art
/// provider seam and Sam's final assets land. All state and logic live in
/// `SandboxViewModel` — this file is gestures and layout only.
///
struct SandboxView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SandboxViewModel?

    /// Endpoints of the in-flight brush stroke (screen space), for segment clearing.
    @State private var lastBrushPoint: CGPoint?

    /// A pest being flung off-screen (drives the throw animation, then removal).
    @State private var flyingPest: FlyingPest?

    /// Species being dragged out of the frag palette (nil when not dragging).
    @State private var paletteDragSpecies: String?

    /// Brief sparkle marker where a brush stroke cleared cells.
    @State private var sparkleAt: CGPoint?

    /// Pests currently executing their vertical squash & fade-out smush animation (DEC-034).
    @State private var smushedPestIDs: Set<String> = []

    /// The live tick timer (DEC-031): advances the reef by one refresh slice while this
    /// screen is visible. Only active in the personal (non-exhibition) app — exhibition
    /// mode drives growth through the Fast Forward button instead.
    private let ticker = Timer.publish(every: SandboxViewModel.tickInterval, on: .main, in: .common).autoconnect()

    struct FlyingPest: Equatable {
        let fragID: UUID
        let pestIndex: Int
        let start: CGPoint
        let velocity: CGPoint
    }

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

                    // The whole care-loop UI is gated together: the playground is
                    // a bare field, so every overlay that is not the reef itself
                    // stays unbuilt until the flag goes back to `false`.
                    if !PlaygroundMode.isEnabled {
                        if viewModel.guidedPlantPhase == .awaitingRubbleClear {
                            coldOpenInstruction(text: "Flick away the dead rubble to uncover the living coral!")
                        } else if viewModel.guidedPlantPhase == .awaitingFragTap {
                            coldOpenInstruction(text: "Drag the living fragment onto the sand to plant it!")
                        } else if viewModel.guidedPlantPhase == .awaitingPlant {
                            guidePulse(viewModel: viewModel, seabedY: seabedY, viewportWidth: geometry.size.width)
                            coldOpenInstruction(text: "Drop the fragment onto the seabed!")
                        }

                        toolOverlay(viewModel: viewModel)

                        if viewModel.isPlantingUnlocked {
                            fragPalette(viewModel: viewModel, seabedY: seabedY)
                        }

                        if viewModel.showPestTooltip {
                            pestTooltip(viewModel: viewModel)
                        }

                        if let sparkleAt {
                            Image(systemName: "sparkle")
                                .font(.title)
                                .foregroundStyle(.white)
                                .position(sparkleAt)
                                .transition(.opacity)
                        }

                        if viewModel.pendingDiagnostic != nil {
                            diagnosticCard(viewModel: viewModel)
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
        // Corals are planted in the seabed layer, so they translate by the sand's
        // own parallax ratio — not by the raw scroll offset. Using `scrollX`
        // directly made the reef slide across the sand at five times its speed.
        let seabedOffset = ParallaxMetrics.seabedOffset(scrollX: viewModel.scrollX)

        ForEach(viewModel.canvas?.coralFrags ?? [], id: \.id) { frag in
            let coral = frag.snapshotForInteraction
            let footprint = CoralGeometry.footprint(for: coral)
            // DEC-009: the unplanted survivor carries an extra glow so it reads as
            // the one living thing in a field of rubble (its pink sprite comes from
            // CoralGeometry — all living babies render colored).
            let isSurvivor = frag.id == viewModel.survivorFrag?.id
            let assetName = footprint.assetName
            let isLifted = viewModel.liftedFragID == frag.id
            let screenX = (isLifted ? viewModel.liftedFragPosition.x : coral.xPos) + seabedOffset
            // yPos is height *above the seabed* — a lifted frag at y 0 sits on the sand,
            // not at the top of the screen.
            let baseY = seabedY - (isLifted ? viewModel.liftedFragPosition.y : coral.yPos)

            ZStack {
                coralArtView(viewModel: viewModel, frag: frag, assetName: assetName, footprint: footprint)
                    .scaleEffect(isLifted ? 1.15 : 1.0)
                    .shadow(color: isLifted ? .white.opacity(0.6) : .clear, radius: 12)
                    .shadow(color: (isSurvivor && viewModel.isSurvivorUncovered) ? .yellow.opacity(0.9) : .clear, radius: 20)

                // Mid-fi algae overlay: brown haze over the coral, opacity tracks
                // the derived coverage (DEC-018 grid; per-cell mask comes with art).
                if !frag.isDead && frag.algaePercentage > 0.02 {
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color(red: 0.35, green: 0.3, blue: 0.15).opacity(frag.algaePercentage * 0.5))
                        .frame(width: footprint.size.width, height: footprint.size.height)
                        .blur(radius: 14)
                        .allowsHitTesting(false)
                }

                // Pests sit on the coral (positions derived from index; mid-fi).
                ForEach(Array(frag.activePredators.enumerated()), id: \.offset) { index, _ in
                    pestView(viewModel: viewModel, frag: frag, index: index, footprint: footprint)
                }
            }
            .frame(width: footprint.size.width, height: footprint.size.height)
            .contentShape(Rectangle())
            .position(x: screenX, y: baseY - footprint.size.height / 2)
            .gesture(
                (isSurvivor && !viewModel.isSurvivorUncovered)
                    ? nil
                    : coralDrag(viewModel: viewModel, frag: frag, seabedY: seabedY)
            )
            .onTapGesture {
                if !isSurvivor || viewModel.isSurvivorUncovered {
                    handleCoralTap(viewModel: viewModel, frag: frag)
                }
            }
        }

        if let canvas = viewModel.canvas, !canvas.guidedPlantDone, let survivor = viewModel.survivorFrag {
            rubblePileLayer(viewModel: viewModel, survivor: survivor, seabedY: seabedY, seabedOffset: seabedOffset)
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
            // Before planting (e.g. cold open survivor frag), display at frame 0 (growthProgress: 0.0).
            // Once planted, the simulation advances growthProgress, scrubbing the Lottie frames slowly.
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

    /// Pest view using Snail vector asset with tap-to-smush height-squash and drag-to-flick (DEC-032, DEC-034).
    @ViewBuilder
    private func pestView(viewModel: SandboxViewModel, frag: CoralFrag, index: Int, footprint: CoralGeometry.Footprint) -> some View {
        let local = CGPoint(x: 0.35 + 0.3 * Double(index), y: 0.4)
        let isFlying = flyingPest?.fragID == frag.id && flyingPest?.pestIndex == index
        let pestKey = "\(frag.id)-\(index)"
        let isSmushed = smushedPestIDs.contains(pestKey)

        Image("Snail")
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
            .scaleEffect(x: isSmushed ? 1.35 : 1.0, y: isSmushed ? 0.2 : 1.0, anchor: .bottom)
            .opacity(isSmushed ? 0.0 : (isFlying ? 0.9 : 1.0))
            .position(x: local.x * footprint.size.width, y: local.y * footprint.size.height)
            .offset(isFlying ? flyOffset(for: flyingPest) : .zero)
            .onTapGesture {
                handlePestTap(fragID: frag.id, index: index, viewModel: viewModel)
            }
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onEnded { value in
                        let velocity = CGPoint(x: value.velocity.width, y: value.velocity.height)
                        guard Physics.isFlick(velocity: velocity) else {
                            handlePestTap(fragID: frag.id, index: index, viewModel: viewModel)
                            return
                        }
                        // Flick: animate along the ballistic arc, then remove (DEC-012).
                        flyingPest = FlyingPest(fragID: frag.id, pestIndex: index, start: .zero, velocity: velocity)
                        let flight = Physics.despawnTime(
                            from: .zero,
                            velocity: velocity,
                            viewport: CGRect(origin: .zero, size: CGSize(width: 2000, height: 1000))
                        ) ?? 0.6
                        withAnimation(.easeIn(duration: min(flight, 0.8))) {
                            flyingPest = FlyingPest(fragID: frag.id, pestIndex: index, start: .zero, velocity: velocity)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + min(flight, 0.8)) {
                            _ = viewModel.removePest(at: index, on: frag.id)
                            flyingPest = nil
                            viewModel.dismissPestTooltip()
                        }
                    }
            )
    }

    private func handlePestTap(fragID: UUID, index: Int, viewModel: SandboxViewModel) {
        let key = "\(fragID)-\(index)"
        guard !smushedPestIDs.contains(key) else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            _ = smushedPestIDs.insert(key)
        }
        viewModel.dismissPestTooltip()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            _ = viewModel.removePest(at: index, on: fragID)
            smushedPestIDs.remove(key)
        }
    }

    private func flyOffset(for pest: FlyingPest?) -> CGSize {
        guard let pest else { return .zero }
        // Mid-fi throw: travel along the velocity vector, normalized to a fixed hop.
        let magnitude = max((pest.velocity.x * pest.velocity.x + pest.velocity.y * pest.velocity.y).squareRoot(), 1)
        return CGSize(width: pest.velocity.x / magnitude * 900, height: pest.velocity.y / magnitude * 900)
    }

    // MARK: - Guided First Plant (DEC-009/024)

    /// Pulsing seabed zone shown while the frag is lifted, just right of the
    /// survivor and clamped inside the viewport. Tapping it auto-flies the frag
    /// into place (workflow §2.3B fallback — never hard-block).
    @ViewBuilder
    private func guidePulse(viewModel: SandboxViewModel, seabedY: Double, viewportWidth: Double) -> some View {
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

    // MARK: - Gestures

    /// The coral's drag, routed by the active tool (DEC-026). Brush drags clear
    /// algae segment-by-segment; the guided plant drags the survivor frag.
    /// `minimumDistance: 6` keeps taps free for `onTapGesture` — a zero-distance
    /// drag would swallow them and the guided plant's tap-to-lift would never fire.
    private func coralDrag(viewModel: SandboxViewModel, frag: CoralFrag, seabedY: Double) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                let seabedOffset = ParallaxMetrics.seabedOffset(scrollX: viewModel.scrollX)
                let canvas = CGPoint(x: value.location.x - seabedOffset, y: value.location.y)
                // Outside the playground only the guided first plant is liftable,
                // so a planted coral is fixed where it sits. Here any coral picks
                // up the moment a drag starts on it, and can be moved again and
                // again.
                if PlaygroundMode.isEnabled, viewModel.liftedFragID != frag.id {
                    withAnimation(.spring(response: 0.3, dampingFraction: Physics.sinkDamping)) {
                        viewModel.liftFrag(id: frag.id)
                    }
                }
                if viewModel.liftedFragID == frag.id {
                    // The frag follows the finger in 2D — including up into open
                    // water. `yPos` is height *above* the seabed, so it is the
                    // distance from the sand up to the touch, never negative.
                    viewModel.dragLiftedFrag(to: CGPoint(x: canvas.x, y: liftHeight(of: value.location.y, seabedY: seabedY)))
                } else if viewModel.selectedTool == .sponge {
                    if let last = lastBrushPoint {
                        let cleared = viewModel.applyBrushSegment(from: last, to: canvas, seabedY: seabedY)
                        if !cleared.isEmpty { sparkleAt = value.location }
                    }
                    lastBrushPoint = canvas
                }
            }
            .onEnded { _ in
                if viewModel.liftedFragID == frag.id {
                    // Released in open water, the frag sinks; the further it has to
                    // fall, the longer the settle takes. The fall is measured to
                    // where it will actually come to rest in the sand band — not
                    // to the container floor, or nudging a coral a few points
                    // within the band would get a full-length spring.
                    let dropHeight = viewModel.liftedFragPosition.y
                    let resting = viewModel.restingHeight(
                        forDropHeight: dropHeight,
                        atX: viewModel.liftedFragPosition.x
                    )
                    let response = Physics.sinkResponse(
                        fallHeight: dropHeight - resting,
                        viewportHeight: seabedY
                    )

                    // The descent animates view-model state, not the model: a
                    // SwiftData write does not carry the transaction, which is
                    // why sinking used to ignore this spring entirely.
                    withAnimation(.spring(response: response, dampingFraction: Physics.sinkDamping)) {
                        viewModel.dragLiftedFrag(
                            to: CGPoint(x: viewModel.liftedFragPosition.x, y: resting)
                        )
                    }

                    // Commit once it has visually arrived. The position already
                    // matches, so only the lift scale and glow change here.
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

    /// Touch point converted to height above the seabed, clamped at the sand.
    private func liftHeight(of screenY: Double, seabedY: Double) -> Double {
        max(0, seabedY - screenY)
    }

    /// The settle a frag uses on its way down to the sand. Water is a fluid
    /// material, so the spring is gentle and its duration scales with the drop
    /// height — a release at the surface drifts, a release at ankle height just
    /// beds in. The light overshoot reads as the frag settling into the sand.
    private func sinkAnimation(fallHeight: Double, seabedY: Double) -> Animation {
        .spring(
            response: Physics.sinkResponse(fallHeight: fallHeight, viewportHeight: seabedY),
            dampingFraction: Physics.sinkDamping
        )
    }

    private func handleCoralTap(viewModel: SandboxViewModel, frag: CoralFrag) {
        if viewModel.guidedPlantPhase == .awaitingFragTap, frag.id == viewModel.survivorFrag?.id {
            viewModel.liftSurvivorFrag()
        }
    }

    // MARK: - Cold Open & Rubble Layer (DEC-009)

    @ViewBuilder
    private func coldOpenInstruction(text: String) -> some View {
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

    @ViewBuilder
    private func rubblePileLayer(
        viewModel: SandboxViewModel,
        survivor: CoralFrag,
        seabedY: Double,
        seabedOffset: Double
    ) -> some View {
        let baseX = survivor.xPos + seabedOffset
        let baseY = seabedY - survivor.yPos - 20

        ForEach(viewModel.rubblePieces) { rubble in
            if !rubble.isCleared {
                let pieceX = baseX + (rubble.isFlicked ? rubble.flickTargetOffset.x : rubble.offset.x)
                let pieceY = baseY + (rubble.isFlicked ? rubble.flickTargetOffset.y : rubble.offset.y)

                Image(rubble.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 54)
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

    // MARK: - Tool Overlay (DEC-007, DEC-032: on-canvas Sponge tool)

    @ViewBuilder
    private func toolOverlay(viewModel: SandboxViewModel) -> some View {
        VStack {
            HStack(spacing: 10) {
                Spacer()

                // 10x Fast Forward Speed (30s timer countdown)
                fastForwardButton(viewModel: viewModel)

                // 100x Debug Speed (Press and Hold)
                debugSpeedButton(viewModel: viewModel)
            }
            .padding(.horizontal, 16)
            .padding(.top, 56) // clear safe area status bar

            Spacer()

            HStack(spacing: 12) {
                spongeToolButton(viewModel: viewModel)
            }
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func fastForwardButton(viewModel: SandboxViewModel) -> some View {
        let isActive = viewModel.isFastForward10xActive
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.activate10xFastForward(duration: 30.0)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "forward.fill")
                    .font(.subheadline.bold())
                if isActive {
                    Text("10x \(Int(ceil(viewModel.fastForwardRemainingSeconds)))s")
                        .font(.callout.monospacedDigit().bold())
                } else {
                    Text("10x FF")
                        .font(.callout.bold())
                }
            }
            .foregroundStyle(isActive ? .cyan : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive ? Color.black.opacity(0.8) : Color.black.opacity(0.45))
                    .overlay(
                        Capsule()
                            .stroke(isActive ? Color.cyan : Color.white.opacity(0.3), lineWidth: isActive ? 2 : 1)
                    )
            )
            .shadow(color: isActive ? Color.cyan.opacity(0.6) : .clear, radius: 8)
        }
        .accessibilityLabel("10x Fast Forward speed for 30 seconds")
    }

    private func debugSpeedButton(viewModel: SandboxViewModel) -> some View {
        let isActive = viewModel.isDebug100xActive
        return HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.subheadline.bold())
            Text("100x")
                .font(.callout.bold())
        }
        .foregroundStyle(isActive ? .orange : .white.opacity(0.9))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(isActive ? Color.orange.opacity(0.35) : Color.black.opacity(0.45))
                .overlay(
                    Capsule()
                        .stroke(isActive ? Color.orange : Color.white.opacity(0.3), lineWidth: isActive ? 2 : 1)
                )
        )
        .shadow(color: isActive ? Color.orange.opacity(0.8) : .clear, radius: 8)
        .scaleEffect(isActive ? 1.08 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isActive)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !viewModel.isDebug100xActive {
                        viewModel.setDebug100xActive(true)
                    }
                }
                .onEnded { _ in
                    viewModel.setDebug100xActive(false)
                }
        )
        .accessibilityLabel("Hold for 100x debug speed")
    }

    private func spongeToolButton(viewModel: SandboxViewModel) -> some View {
        let isSelected = viewModel.selectedTool == .sponge
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                viewModel.selectedTool = isSelected ? nil : .sponge
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.white.opacity(0.95) : Color.black.opacity(0.4))
                    .frame(width: 58, height: 58)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.cyan : Color.white.opacity(0.3), lineWidth: isSelected ? 2.5 : 1)
                    )
                    .shadow(color: isSelected ? Color.cyan.opacity(0.6) : .clear, radius: 8)

                Image("Sponge")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
            }
        }
        .accessibilityLabel("Sponge cleaning tool")
    }

    // MARK: - Frag Palette (DEC-029)

    @ViewBuilder
    private func fragPalette(viewModel: SandboxViewModel, seabedY: Double) -> some View {
        HStack(spacing: 16) {
            ForEach(viewModel.config.availableSpecies, id: \.self) { species in
                Image("Fragment1")
                    .resizable()
                    .frame(width: 34, height: 80)
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        Text(species).font(.caption2).foregroundStyle(.white).offset(y: 52)
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                paletteDragSpecies = species
                                viewModel.liftedFragPosition = CGPoint(
                                    x: value.location.x - ParallaxMetrics.seabedOffset(scrollX: viewModel.scrollX),
                                    y: liftHeight(of: value.location.y, seabedY: seabedY)
                                )
                            }
                            .onEnded { value in
                                let fallHeight = liftHeight(of: value.location.y, seabedY: seabedY)
                                let drop = CGPoint(
                                    x: value.location.x - ParallaxMetrics.seabedOffset(scrollX: viewModel.scrollX),
                                    y: fallHeight
                                )
                                // Plant at the height it was released from, then settle
                                // it down to the sand on the next runloop pass. Inserting
                                // straight at y 0 would pop the frag onto the seabed with
                                // nothing to animate from.
                                //
                                // KNOWN GAP: `settleFrag` writes a SwiftData `@Model`
                                // property, and such a write does not carry a
                                // `withAnimation` transaction — so this descent snaps
                                // rather than sinking. The coral drag above works around
                                // it by animating view-model state and committing after;
                                // the palette drop needs the same treatment. Unreachable
                                // while `PlaygroundMode` hides the palette.
                                let planted = viewModel.plantFrag(species: species, at: drop)
                                paletteDragSpecies = nil
                                if let planted {
                                    let resting = viewModel.restingHeight(forDropHeight: fallHeight, atX: drop.x)
                                    DispatchQueue.main.async {
                                        withAnimation(sinkAnimation(fallHeight: fallHeight - resting, seabedY: seabedY)) {
                                            viewModel.settleFrag(id: planted.id, fromDropHeight: fallHeight)
                                        }
                                    }
                                }
                            }
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 76)

        // Drag preview follows the finger.
        if paletteDragSpecies != nil {
            Image("Fragment1")
                .resizable()
                .frame(width: 45, height: 110)
                .opacity(0.85)
                .position(
                    x: viewModel.liftedFragPosition.x + ParallaxMetrics.seabedOffset(scrollX: viewModel.scrollX),
                    y: seabedY - viewModel.liftedFragPosition.y - 55
                )
                .allowsHitTesting(false)
        }
    }

    // MARK: - Pest Tooltip (DEC-012: one-time)

    @ViewBuilder
    private func pestTooltip(viewModel: SandboxViewModel) -> some View {
        VStack {
            Text("A snail is eating your coral! Tap it to smush it, or flick it away.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 40)
                .onTapGesture { viewModel.dismissPestTooltip() }
            Spacer()
        }
        .padding(.top, 60)
        .transition(.opacity)
    }

    // MARK: - Diagnostic Card (workflow §3.1)

    @ViewBuilder
    private func diagnosticCard(viewModel: SandboxViewModel) -> some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("5 Years Later")
                    .font(.title2.bold())
                if let message = viewModel.diagnosticMessage {
                    Text(message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                Button("Back to my reef") {
                    withAnimation { viewModel.dismissDiagnosticCard() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .transition(.opacity)
    }
}

#Preview {
    SandboxView()
        .modelContainer(for: [UserProfile.self, ReefCanvas.self, CoralFrag.self, NGOConfig.self], inMemory: true)
}
