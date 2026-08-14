import Foundation
import SwiftData

/// **SandboxViewModel: View ↔ Domain Coordinator (TASK-MVP-202)**
///
/// Sits between the SwiftUI layer and the domain. Owns the parallax scroll offset
/// (DEC-021), maps the persisted `@Model` graph to and from `ReefState` value
/// snapshots (DEC-020), and turns care gestures into domain mutations. Views never
/// touch `EcoEngine` or `AlgaeCoverage` directly.
///
/// Hard Reset is deliberately **not** here — it lives in Settings only (DEC-005).
///
@MainActor
@Observable
public final class SandboxViewModel {

    // MARK: - Tools & Published Surface

    /// The active on-canvas tool (DEC-007: overlays on the canvas, no side dashboard).
    public enum Tool {
        case brush
        case hand
        case plant
    }

    /// Horizontal parallax offset, owned here so the entity layer can hit-test
    /// corals and pests against the same value the renderer uses (DEC-021).
    /// Passed to `ParallaxScrollView` as a `Binding` once issue #6 lands.
    public var scrollX: Double = 0

    /// The active canvas, loaded from (or created in) SwiftData.
    public private(set) var canvas: ReefCanvas?

    /// The regional config driving this session's threats. Exhibition: Bali (DEC-003).
    public private(set) var config: NGOConfig

    /// The currently selected care tool.
    public var selectedTool: Tool = .hand

    /// Set when a Fast Forward completes; the view presents the Diagnostic Card (workflow §3.1).
    public var pendingDiagnostic: ReefState?

    private let modelContext: ModelContext

    /// Session threat state, derived from the config. `heatwaveAllowed == false`
    /// (DEC-025) keeps bleaching dormant: temperature never exceeds the baseline.
    public private(set) var threats: ThreatVector

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

    /// True when a saved canvas exists — the router's only question.
    /// First launch → Onboarding Page; returning → Coral Screen.
    public var hasSavedState: Bool { canvas != nil }

    /// Loads the saved canvas, or creates the dead-rubble starting state with one
    /// surviving Staghorn fragment (DEC-009) on first launch.
    public func loadOrCreateCanvas() {
        let descriptor = FetchDescriptor<ReefCanvas>()
        if let existing = try? modelContext.fetch(descriptor).first {
            canvas = existing
            return
        }

        let survivor = CoralFrag(species: "Acropora", xPos: 200, yPos: 0, growthProgress: 0.15)
        let canvas = ReefCanvas(ngoRegion: config.regionName, coralFrags: [survivor])
        modelContext.insert(canvas)
        self.canvas = canvas
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
    /// Fragments in the snapshot with no persisted twin are inserted (e.g. planted
    /// while simulating); dead corals are kept — they render as rubble (PRD §4.6).
    public func commit(_ state: ReefState) {
        guard let canvas else { return }
        var fragsByID = Dictionary(uniqueKeysWithValues: canvas.coralFrags.map { ($0.id, $0) })

        for coral in state.corals {
            if let frag = fragsByID.removeValue(forKey: coral.id) {
                frag.species = coral.species
                frag.xPos = coral.xPos
                frag.yPos = coral.yPos
                frag.growthProgress = coral.growthProgress
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

    // MARK: - Care Actions

    /// Plants a frag on the seabed at a canvas-space point (DEC-024: direct planting,
    /// no structures). The drop is clamped to the playable bounds (DEBT-001).
    @discardableResult
    public func plantFrag(species: String, at point: CGPoint) -> CoralFrag? {
        guard let canvas, config.availableSpecies.contains(species) else { return nil }
        let drop = Physics.clampedDrop(point, canvasWidth: canvas.canvasWidth)
        let frag = CoralFrag(species: species, xPos: drop.x, yPos: drop.y)
        modelContext.insert(frag)
        canvas.coralFrags.append(frag)
        save()
        return frag
    }

    /// Clears algae along a brush stroke (DEC-012). `start`/`end` are in normalised
    /// coral-local space; interpolation between drag samples prevents uncleaned
    /// stripes on fast swipes (DEC-018). Returns the cells that just became clean
    /// so the view can fire sparkles and haptics.
    @discardableResult
    public func brushStroke(from start: CGPoint, to end: CGPoint, on fragID: UUID) -> [Int] {
        guard let frag = canvas?.coralFrags.first(where: { $0.id == fragID }) else { return [] }
        var coverage = AlgaeCoverage(cells: frag.algaeCells)
        let cleared = coverage.clear(from: start, to: end)
        frag.algaeCells = coverage.cells
        save()
        return cleared
    }

    /// Taps a pest to smush it (DEC-012). Returns true if a pest was removed.
    @discardableResult
    public func smushPest(_ pest: String, on fragID: UUID) -> Bool {
        guard let frag = canvas?.coralFrags.first(where: { $0.id == fragID }),
              let index = frag.activePredators.firstIndex(of: pest) else { return false }
        frag.activePredators.remove(at: index)
        save()
        return true
    }

    /// Removes a pest via the Hand tool (DEC-012). The release velocity decides how
    /// the *view* animates the removal — above 100 pt/s it plays the ballistic throw
    /// (`Physics.throwPosition` / `despawnTime`), below it the tap-smush squash.
    /// The domain outcome is identical either way: the pest leaves the fragment.
    @discardableResult
    public func flickPest(_ pest: String, velocity: CGPoint, on fragID: UUID) -> Bool {
        _ = Physics.isFlick(velocity: velocity) // animation branch lives in the view
        return smushPest(pest, on: fragID)
    }

    /// Toggles an agricultural runoff shock for the session (exhibition threat;
    /// heatwaves are never toggled — DEC-025).
    public func setRunoffShock(_ active: Bool) {
        guard config.runoffShockAllowed else { return }
        threats.agriculturalRunoff = active
    }

    /// Advances a single month of active play.
    public func tick() {
        commit(EcoEngine.step(state: snapshot(), threats: threats, months: 1))
    }

    /// Simulates 5–10 years, then hands the steady state to the Diagnostic Card
    /// (workflow §2.3C, §3.1). Computed on a snapshot first (DEC-020), committed once.
    public func fastForward(years: Int = 5) {
        let outcome = EcoEngine.step(state: snapshot(), threats: threats, months: years * 12)
        commit(outcome)
        pendingDiagnostic = outcome
    }

    /// Dismisses the Diagnostic Card after the user reads it (Kolb: reflection → experimentation).
    public func dismissDiagnostic() {
        pendingDiagnostic = nil
    }

    // MARK: - Persistence

    private func save() {
        try? modelContext.save()
    }
}
