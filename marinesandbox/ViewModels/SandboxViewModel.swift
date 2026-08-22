import CoreGraphics
import Foundation
import SwiftData

/// **SandboxViewModel: View ↔ Domain Coordinator (TASK-MVP-202)**
///
/// Sits between the SwiftUI layer and the domain. Owns the parallax scroll offset
/// (DEC-021), maps the persisted `@Model` graph to and from `ReefState` value
/// snapshots (DEC-020), and turns care gestures into domain mutations. Views never
/// touch `EcoEngine` or `AlgaeCoverage` directly.
///
/// Modularized into focused extensions:
/// - `SandboxViewModel+Planting.swift`: Guided first plant, frag lifting/dragging, cold open rubble.
/// - `SandboxViewModel+CareLoop.swift`: Algae brushing, pest mitigation, hit routing, threats.
/// - `SandboxViewModel+Simulation.swift`: Ticking, speed multipliers, fast forward, diagnostics.
///
@MainActor
@Observable
public final class SandboxViewModel {

    // MARK: - Tools & Published Surface

    /// The active on-canvas tool (DEC-032: single Sponge tool + bare-hand default).
    public enum Tool: String, CaseIterable, Sendable {
        case sponge
    }

    /// Horizontal parallax offset, owned here so the entity layer can hit-test
    /// corals and pests against the same value the renderer uses (DEC-021).
    public var scrollX: CGFloat = 0.0

    /// The active canvas, loaded from (or created in) SwiftData.
    public internal(set) var canvas: ReefCanvas?

    /// The regional config driving this session's threats. Exhibition: Bali (DEC-003).
    public internal(set) var config: NGOConfig

    /// The currently selected care tool (`nil` represents default bare-hand mode, DEC-032).
    public var selectedTool: Tool? = nil

    /// Set when a Fast Forward completes; the view presents the Diagnostic Card (workflow §3.1).
    public var pendingDiagnostic: ReefState?

    /// Plain-language reflection shown on the Diagnostic Card after Fast Forward.
    public var diagnosticMessage: String?

    public var lottiePlaybackTargets: [UUID: Double] = [:]

    /// The frag currently lifted by the user's finger.
    public var liftedFragID: UUID?

    /// Where the lifted frag is, in canvas coordinates.
    public var liftedFragPosition: CGPoint = .zero

    /// Dead rubble pieces covering the survivor fragment in the cold open (DEC-009).
    public var rubblePieces: [RubblePiece] = []

    /// Off-screen snails actively crawling toward a coral (DEC-034).
    public var crawlingSnails: [CrawlingSnail] = []

    /// Remaining seconds on the 10x speed up boost timer (30s duration).
    public var fastForwardRemainingSeconds: Double = 0.0

    /// True when debug 100x speed hold button is actively pressed.
    public var isDebug100xActive: Bool = false

    /// Corals that have already yielded a new floating fragment upon reaching teenage.
    public var rewardedTeenageCoralIDs: Set<UUID> = []

    /// Set when the first pest ever spawns; the view shows the one-time tooltip (DEC-012).
    public var showPestTooltip = false

    /// Width of one seabed artwork block.
    public internal(set) var seabedBlockWidth: CGFloat = 0

    /// Fallback sand height used only before the artwork can be measured.
    public internal(set) var seabedFallbackHeight: CGFloat = 0

    let modelContext: ModelContext

    /// Session threat state, derived from the config (DEC-025).
    public internal(set) var threats: ThreatVector

    public init(modelContext: ModelContext, config: NGOConfig = .exhibitionBali) {
        self.modelContext = modelContext
        self.config = config
        self.threats = ThreatVector(
            agriculturalRunoff: false,
            isHeatwaveActive: config.heatwaveAllowed,
            waterTemperature: config.baselineTemperature
        )
    }

    // MARK: - Loading & First-Launch Routing (DEC-008, workflow §2.1)

    /// True when a saved canvas exists.
    public var hasSavedState: Bool { canvas != nil }

    /// Loads the saved canvas, or creates the dead-rubble starting state on first launch.
    public func loadOrCreateCanvas() {
        let descriptor = FetchDescriptor<ReefCanvas>()
        if let existing = try? modelContext.fetch(descriptor).first {
            canvas = existing
            setupRubblePileIfNeeded()
            runCatchUpIfNeeded()
            return
        }

        let survivor = CoralFrag(species: "Acropora", xPos: 120, yPos: 35, growthProgress: 0.0)
        let canvas = ReefCanvas(ngoRegion: config.regionName, coralFrags: [survivor])
        modelContext.insert(canvas)
        self.canvas = canvas
        setupRubblePileIfNeeded()
        save()
    }

    /// Advances the reef by the offline gap, gracefully (DEC-031).
    private func runCatchUpIfNeeded() {
        guard let canvas, !config.isExhibitionMode, canvas.guidedPlantDone else {
            canvas?.lastSeenAt = Date()
            save()
            return
        }
        let now = Date()
        let elapsed = now.timeIntervalSince(canvas.lastSeenAt)
        guard elapsed > 1 else { return }
        let before = snapshot()
        let outcome = EcoEngine.advance(state: before, threats: threats, elapsed: elapsed, allowDeath: false)
        commit(outcome)
        lottiePlaybackTargets = Dictionary(uniqueKeysWithValues: zip(before.corals, outcome.corals).compactMap { before, after in
            before.growthProgress == after.growthProgress ? nil : (after.id, after.growthProgress)
        })
        canvas.lastSeenAt = now
        save()
    }

    // MARK: - Snapshot Adapter (DEC-020 seam)

    /// Maps the persisted canvas to a value snapshot the engine can simulate.
    public func snapshot() -> ReefState {
        let corals = (canvas?.coralFrags ?? []).map { frag in
            CoralState(
                id: frag.id,
                species: frag.species,
                xPos: frag.xPos,
                yPos: frag.yPos,
                growthProgress: frag.growthProgress,
                plantedAt: frag.plantedAt,
                coverage: AlgaeCoverage(cells: frag.algaeCells),
                predatorDamage: frag.predatorDamage,
                activePredators: frag.activePredators,
                isBleached: frag.isBleached,
                isDead: frag.isDead
            )
        }
        return ReefState(
            ngoRegion: canvas?.ngoRegion ?? config.regionName,
            canvasWidth: canvas?.canvasWidth ?? 2000.0,
            corals: corals
        )
    }

    /// Writes a simulated snapshot back onto the persisted models, matched by `id`.
    public func commit(_ state: ReefState) {
        guard let canvas else { return }
        var fragsByID = Dictionary(uniqueKeysWithValues: canvas.coralFrags.map { ($0.id, $0) })

        for coral in state.corals {
            if let frag = fragsByID.removeValue(forKey: coral.id) {
                frag.species = coral.species
                frag.xPos = coral.xPos
                frag.yPos = coral.yPos
                frag.growthProgress = coral.growthProgress
                frag.plantedAt = coral.plantedAt
                frag.algaeCells = coral.coverage.cells
                frag.predatorDamage = coral.predatorDamage
                frag.activePredators = coral.activePredators
                frag.isBleached = coral.isBleached
                frag.isDead = coral.isDead
            } else {
                let frag = CoralFrag(
                    id: coral.id,
                    species: coral.species,
                    xPos: coral.xPos,
                    yPos: coral.yPos,
                    growthProgress: coral.growthProgress,
                    plantedAt: coral.plantedAt,
                    algaeCells: coral.coverage.cells,
                    predatorDamage: coral.predatorDamage,
                    activePredators: coral.activePredators,
                    isBleached: coral.isBleached,
                    isDead: coral.isDead
                )
                modelContext.insert(frag)
                canvas.coralFrags.append(frag)
            }
        }
        save()
    }

    /// Records the field's geometry: plantable sand band and playable reach.
    public func updateFieldGeometry(viewportWidth: CGFloat, viewportHeight: CGFloat) {
        seabedBlockWidth = viewportWidth * ParallaxMetrics.seabedWidthScale
        seabedFallbackHeight = viewportHeight * 0.19

        guard let canvas, viewportWidth > 0 else { return }
        let width = Double(ParallaxMetrics.playableWidth(viewportWidth: viewportWidth))
        guard abs(canvas.canvasWidth - width) > 0.5 else { return }

        canvas.canvasWidth = width
        for frag in canvas.coralFrags {
            let inside = Physics.clampedDrop(
                CGPoint(x: frag.xPos, y: frag.yPos),
                canvasWidth: width
            )
            frag.xPos = inside.x
        }
        save()
    }

    // MARK: - Persistence

    func save() {
        try? modelContext.save()
    }
}

/// Model → domain projection for hit-testing and interaction routing (DEC-020).
extension CoralFrag {
    var snapshotForInteraction: CoralState {
        CoralState(
            id: id,
            species: species,
            xPos: xPos,
            yPos: yPos,
            growthProgress: growthProgress,
            plantedAt: plantedAt,
            coverage: AlgaeCoverage(cells: algaeCells),
            predatorDamage: predatorDamage,
            activePredators: activePredators,
            isBleached: isBleached,
            isDead: isDead
        )
    }
}
