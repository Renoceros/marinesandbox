import SwiftUI
import SwiftData

/// **ContentView: Coral Screen shell (mid-fi)**
///
/// The parallax world with the entity layer on top: coral sprites rendered from the
/// persisted canvas, positioned in canvas space and panned by the shared `scrollX`
/// binding (DEC-021). Interaction gestures (tap-to-plant, brush, pest flick) land
/// with the Phase 3 `SandboxView` — this shell exists so the reef is visible and
/// the coordinate plumbing is exercised end-to-end.
///
struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SandboxViewModel?

    var body: some View {
        GeometryReader { geometry in
            if let viewModel {
                ZStack(alignment: .bottomLeading) {
                    ParallaxScrollView(scrollX: Binding(
                        get: { CGFloat(viewModel.scrollX) },
                        set: { viewModel.scrollX = Double($0) }
                    ))

                    // Entity layer: corals anchored to the seabed at viewport bottom.
                    // Dead corals render as desaturated rubble (PRD §4.6).
                    ForEach(viewModel.canvas?.coralFrags ?? [], id: \.id) { frag in
                        let coral = frag.snapshot
                        let footprint = CoralGeometry.footprint(for: coral)
                        Image(footprint.assetName)
                            .resizable()
                            .frame(width: footprint.size.width, height: footprint.size.height)
                            .saturation(frag.isDead ? 0 : 1)
                            .opacity(frag.isDead ? 0.5 : 1)
                            .position(
                                x: coral.xPos + viewModel.scrollX,
                                y: geometry.size.height - coral.yPos - footprint.size.height / 2
                            )
                    }
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
}

/// Lightweight model → domain projection for rendering. The authoritative adapter
/// for simulation lives on `SandboxViewModel` (DEC-020); this is display-only.
private extension CoralFrag {
    var snapshot: CoralState {
        CoralState(
            id: id,
            species: species,
            xPos: xPos,
            yPos: yPos,
            growthProgress: growthProgress,
            coverage: AlgaeCoverage(cells: algaeCells),
            predatorDamage: predatorDamage,
            activePredators: activePredators,
            isBleached: isBleached,
            isDead: isDead
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProfile.self, ReefCanvas.self, CoralFrag.self, NGOConfig.self], inMemory: true)
}
