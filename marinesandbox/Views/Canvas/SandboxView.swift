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

                    if viewModel.guidedPlantPhase == .awaitingPlant {
                        guidePulse(viewModel: viewModel, seabedY: seabedY, viewportWidth: geometry.size.width)
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
                .onReceive(ticker) { _ in
                    // DEC-031: the live auto-tick runs only in the personal app.
                    // Exhibition mode drives growth via the Fast Forward button.
                    guard !viewModel.config.isExhibitionMode else { return }
                    viewModel.tickLive()
                }
            } else {
                Color(hex: "3BAFED").ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
        .onAppear {
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
        ForEach(viewModel.canvas?.coralFrags ?? [], id: \.id) { frag in
            let coral = frag.snapshotForInteraction
            let footprint = CoralGeometry.footprint(for: coral)
            // DEC-009: the unplanted survivor carries an extra glow so it reads as
            // the one living thing in a field of rubble (its pink sprite comes from
            // CoralGeometry — all living babies render colored).
            let isSurvivor = frag.id == viewModel.survivorFrag?.id
            let assetName = footprint.assetName
            let isLifted = viewModel.liftedFragID == frag.id
            let screenX = (isLifted ? viewModel.liftedFragPosition.x : coral.xPos) + viewModel.scrollX
            // yPos is height *above the seabed* — a lifted frag at y 0 sits on the sand,
            // not at the top of the screen.
            let baseY = seabedY - (isLifted ? viewModel.liftedFragPosition.y : coral.yPos)

            ZStack {
                coralArtView(frag: frag, assetName: assetName, footprint: footprint)
                    .scaleEffect(isLifted ? 1.15 : 1.0)
                    .shadow(color: isLifted ? .white.opacity(0.6) : .clear, radius: 12)
                    .shadow(color: isSurvivor ? .yellow.opacity(0.8) : .clear, radius: 18)

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
            .gesture(coralDrag(viewModel: viewModel, frag: frag, seabedY: seabedY))
            .onTapGesture { handleCoralTap(viewModel: viewModel, frag: frag) }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLifted)
        }
    }

    @ViewBuilder
    private func coralArtView(
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
            LottieCoralView(coralID: frag.id, growthProgress: frag.growthProgress)
                .frame(width: footprint.size.width, height: footprint.size.height)
        }
    }

    /// Pest dot with tap-to-smush and drag-to-flick (DEC-012). Position derived
    /// from the pest index so model and view never disagree about where pests are.
    @ViewBuilder
    private func pestView(viewModel: SandboxViewModel, frag: CoralFrag, index: Int, footprint: CoralGeometry.Footprint) -> some View {
        let local = CGPoint(x: 0.35 + 0.3 * Double(index), y: 0.4)
        let isFlying = flyingPest?.fragID == frag.id && flyingPest?.pestIndex == index

        Circle()
            .fill(Color(red: 0.45, green: 0.25, blue: 0.15))
            .frame(width: 22, height: 22)
            .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1.5))
            .position(x: local.x * footprint.size.width, y: local.y * footprint.size.height)
            .offset(isFlying ? flyOffset(for: flyingPest) : .zero)
            .opacity(isFlying ? 0.9 : 1)
            .onTapGesture {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                    viewModel.dismissPestTooltip()
                    _ = viewModel.removePest(at: index, on: frag.id)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onEnded { value in
                        let velocity = CGPoint(x: value.velocity.width, y: value.velocity.height)
                        guard Physics.isFlick(velocity: velocity) else {
                            _ = viewModel.removePest(at: index, on: frag.id)
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
            .position(x: target.x + viewModel.scrollX, y: target.y)
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
                let canvas = CGPoint(x: value.location.x - viewModel.scrollX, y: value.location.y)
                if viewModel.liftedFragID == frag.id {
                    viewModel.dragLiftedFrag(to: CGPoint(x: canvas.x, y: 0))
                } else if viewModel.selectedTool == .brush {
                    if let last = lastBrushPoint {
                        let cleared = viewModel.applyBrushSegment(from: last, to: canvas, seabedY: seabedY)
                        if !cleared.isEmpty { sparkleAt = value.location }
                    }
                    lastBrushPoint = canvas
                }
            }
            .onEnded { _ in
                if viewModel.liftedFragID == frag.id {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                        viewModel.plantLiftedFrag()
                    }
                }
                lastBrushPoint = nil
            }
    }

    private func handleCoralTap(viewModel: SandboxViewModel, frag: CoralFrag) {
        if viewModel.guidedPlantPhase == .awaitingFragTap, frag.id == viewModel.survivorFrag?.id {
            viewModel.liftSurvivorFrag()
        }
    }

    // MARK: - Tool Overlay (DEC-007: on-canvas, no dashboard)

    @ViewBuilder
    private func toolOverlay(viewModel: SandboxViewModel) -> some View {
        VStack {
            HStack {
                Spacer()
                // DEC-031: the Fast Forward button is the exhibition progression
                // mechanism (tap to jump stages). The personal app grows in real time.
                if viewModel.config.isExhibitionMode {
                    Button {
                        viewModel.performFastForward()
                    } label: {
                        Label("Fast Forward", systemImage: "forward.fill")
                            .font(.callout.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding(.horizontal)
                    .padding(.top, 56) // root ignores safe area — keep clear of the status bar
                }
            }
            Spacer()
            HStack(spacing: 12) {
                toolButton(.hand, icon: "hand.point.up.left.fill", viewModel: viewModel)
                toolButton(.brush, icon: "paintbrush.fill", viewModel: viewModel)
                toolButton(.plant, icon: "leaf.fill", viewModel: viewModel)
            }
            .padding(.bottom, 8)
        }
    }

    private func toolButton(_ tool: SandboxViewModel.Tool, icon: String, viewModel: SandboxViewModel) -> some View {
        Button {
            viewModel.selectedTool = tool
        } label: {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 52, height: 52)
                .background(viewModel.selectedTool == tool ? Color.white.opacity(0.9) : Color.black.opacity(0.35), in: Circle())
                .foregroundStyle(viewModel.selectedTool == tool ? .blue : .white)
        }
        .accessibilityLabel(tool == .hand ? "Hand tool" : tool == .brush ? "Brush tool" : "Plant tool")
    }

    // MARK: - Frag Palette (DEC-029)

    @ViewBuilder
    private func fragPalette(viewModel: SandboxViewModel, seabedY: Double) -> some View {
        if viewModel.selectedTool == .plant {
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
                                        x: value.location.x - viewModel.scrollX,
                                        y: 0
                                    )
                                }
                                .onEnded { value in
                                    let drop = CGPoint(x: value.location.x - viewModel.scrollX, y: 0)
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                                        _ = viewModel.plantFrag(species: species, at: drop)
                                    }
                                    paletteDragSpecies = nil
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
                    .position(x: viewModel.liftedFragPosition.x + viewModel.scrollX, y: seabedY - 130)
                    .allowsHitTesting(false)
            }
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
