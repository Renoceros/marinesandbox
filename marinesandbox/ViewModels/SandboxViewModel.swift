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
    public var scrollX: CGFloat = 0.0

    /// The active canvas, loaded from (or created in) SwiftData.
    public private(set) var canvas: ReefCanvas?

    /// The regional config driving this session's threats. Exhibition: Bali (DEC-003).
    public private(set) var config: NGOConfig

    /// The currently selected care tool.
    public var selectedTool: Tool = .hand

    /// Set when a Fast Forward completes; the view presents the Diagnostic Card (workflow §3.1).
    public var pendingDiagnostic: ReefState?

    /// Plain-language reflection shown on the Diagnostic Card after Fast Forward.
    public var diagnosticMessage: String?

    /// The frag currently lifted by the user's finger (guided plant or palette drag).
    public var liftedFragID: UUID?

    /// Where the lifted frag is, in canvas coordinates (drives the drag preview).
    public var liftedFragPosition: CGPoint = .zero

    /// Set when the first pest ever spawns; the view shows the one-time tooltip (DEC-012).
    public var showPestTooltip = false

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

// MARK: - Gameplay Session (care loop)

extension SandboxViewModel {

    /// Seconds of real time per simulation month (DEC-027). One constant owns the
    /// demo pacing; retune here after floor-testing.
    public static let tickInterval: TimeInterval = 5.0

    /// Fast Forward horizon in years (workflow §2.3C: 5–10 years).
    public static let fastForwardYears: Int = 5

    /// Pest spawn chance per vulnerable coral per tick, and the per-coral cap (DEC-028).
    public static let pestSpawnChance: Double = 0.25
    public static let pestCapPerCoral = 2

    // MARK: Guided First Plant (DEC-009, DEC-024)

    /// Phase of the guided cold open, for the view's highlight/pulse states.
    public enum GuidedPlantPhase {
        /// Nothing highlighted; waiting for the user to tap the survivor frag.
        case awaitingFragTap
        /// Frag lifted; the seabed target zone is pulsing.
        case awaitingPlant
        /// Planted. The steady-state care loop begins.
        case done
    }

    /// The survivor frag from the cold open (nil once the guide is done or if absent).
    public var survivorFrag: CoralFrag? {
        guard let canvas, !canvas.guidedPlantDone else { return nil }
        return canvas.coralFrags.first { !$0.isDead }
    }

    /// Current guide phase, derived from persisted state so an interrupted cold
    /// open resumes correctly on relaunch.
    public var guidedPlantPhase: GuidedPlantPhase {
        if canvas?.guidedPlantDone == true { return .done }
        return liftedFragID == nil ? .awaitingFragTap : .awaitingPlant
    }

    /// Lifts the survivor frag on tap (guide step 1: frag highlights).
    public func liftSurvivorFrag() {
        guard let survivor = survivorFrag else { return }
        liftedFragID = survivor.id
        liftedFragPosition = CGPoint(x: survivor.xPos, y: survivor.yPos)
    }

    /// Drags the lifted frag to a canvas-space point (guide step 2 in progress).
    public func dragLiftedFrag(to point: CGPoint) {
        liftedFragPosition = point
    }

    /// Drops the lifted frag (guide step 3: plant + settle feedback). The drop is
    /// clamped to the playable bounds; a drop always plants — the guide never
    /// hard-blocks (workflow §2.3B fallback).
    public func plantLiftedFrag() {
        guard let canvas, let id = liftedFragID,
              let frag = canvas.coralFrags.first(where: { $0.id == id }) else { return }
        let drop = Physics.clampedDrop(liftedFragPosition, canvasWidth: canvas.canvasWidth)
        frag.xPos = drop.x
        frag.yPos = 0
        canvas.guidedPlantDone = true
        liftedFragID = nil
        save()
    }

    /// Tapping the glowing zone instead of dragging: the frag auto-flies there.
    public func autoPlantSurvivor(at point: CGPoint) {
        guard let survivor = survivorFrag else { return }
        liftedFragID = survivor.id
        liftedFragPosition = point
        plantLiftedFrag()
    }

    // MARK: Additional Planting (DEC-029)

    /// The frag palette appears once any planted coral reaches Teenager —
    /// "the first coral proves healthy" made concrete.
    public var isPlantingUnlocked: Bool {
        canvas?.coralFrags.contains(where: { $0.isTeenager || $0.isAdult }) == true
    }

    // MARK: Hit Routing (DEC-026)

    /// The coral under a canvas-space point, if any. Views call this first:
    /// a hit means the active tool owns the gesture; a miss means the drag pans.
    public func coral(atCanvasPoint point: CGPoint, seabedY: Double) -> CoralFrag? {
        guard let canvas else { return nil }
        let snapshots = canvas.coralFrags.map(\.snapshotForInteraction)
        guard let hit = CoralGeometry.hitTest(corals: snapshots, at: point, seabedY: seabedY) else { return nil }
        return canvas.coralFrags.first { $0.id == hit.id }
    }

    // MARK: Brush (DEC-012, DEC-018)

    /// Applies one brush segment given in canvas space: hit-tests, converts to
    /// coral-local space, clears the crossed cells. Returns cleared cell indices
    /// (for sparkles/haptics), empty when the stroke missed every coral.
    @discardableResult
    public func applyBrushSegment(from start: CGPoint, to end: CGPoint, seabedY: Double) -> [Int] {
        guard let frag = coral(atCanvasPoint: start, seabedY: seabedY)
                ?? coral(atCanvasPoint: end, seabedY: seabedY) else { return [] }
        let snapshot = frag.snapshotForInteraction
        guard let localStart = CoralGeometry.localPoint(in: snapshot, canvasPoint: start, seabedY: seabedY)
                ?? CoralGeometry.localPoint(in: snapshot, canvasPoint: end, seabedY: seabedY),
              let localEnd = CoralGeometry.localPoint(in: snapshot, canvasPoint: end, seabedY: seabedY)
                ?? CoralGeometry.localPoint(in: snapshot, canvasPoint: start, seabedY: seabedY)
        else { return [] }
        return brushStroke(from: localStart, to: localEnd, on: frag.id)
    }

    // MARK: Pests (DEC-028, DEC-012)

    /// Called once per tick by the view's timer. Each living Baby/Teenager coral
    /// with no pests has a 25% chance to gain a Drupella snail (cap 2 per coral).
    /// Adults are spared — their recruited wrasses keep them clean (PRD §3.2).
    public func spawnPestsIfNeeded(random: Double = Double.random(in: 0...1)) {
        guard let canvas else { return }
        var spawned = false
        for frag in canvas.coralFrags {
            guard !frag.isDead, frag.isBaby || frag.isTeenager,
                  frag.activePredators.count < Self.pestCapPerCoral,
                  random < Self.pestSpawnChance else { continue }
            if frag.activePredators.isEmpty && !canvas.coralFrags.contains(where: { !$0.activePredators.isEmpty }) {
                showPestTooltip = true
            }
            frag.activePredators.append("DrupellaSnail")
            spawned = true
        }
        if spawned { save() }
    }

    public func dismissPestTooltip() {
        showPestTooltip = false
    }

    /// Removes one pest from a coral by index — the domain outcome of both the
    /// tap-smush and the flick (the velocity only chooses the view's animation).
    @discardableResult
    public func removePest(at index: Int, on fragID: UUID) -> String? {
        guard let frag = canvas?.coralFrags.first(where: { $0.id == fragID }),
              frag.activePredators.indices.contains(index) else { return nil }
        let pest = frag.activePredators.remove(at: index)
        save()
        return pest
    }

    // MARK: Fast Forward → Diagnostic Card (workflow §2.3C, §3.1)

    /// Simulates 5 years on a snapshot, commits once, and generates the
    /// before/after reflection from what actually changed (Kolb: reflective
    /// observation → active experimentation).
    public func performFastForward() {
        let before = snapshot()
        let outcome = EcoEngine.step(state: before, threats: threats, months: Self.fastForwardYears * 12)
        commit(outcome)
        pendingDiagnostic = outcome
        diagnosticMessage = Self.diagnose(before: before, after: outcome)
    }

    public func dismissDiagnosticCard() {
        pendingDiagnostic = nil
        diagnosticMessage = nil
    }

    /// Builds the card's message from the dominant change. No numbers — the card
    /// is a visual/plain-language reflection, not a dashboard (DEC-007).
    static func diagnose(before: ReefState, after: ReefState) -> String {
        let beforeLiving = before.livingCorals
        let afterLiving = after.livingCorals
        let deaths = beforeLiving.count - afterLiving.count
        let grew = zip(before.corals, after.corals).filter { $0.growthProgress < 0.7 && $1.growthProgress >= 0.7 }

        if deaths > 0 {
            let algaeDeaths = zip(before.corals, after.corals).filter { !$0.isDead && $1.isDead && $1.algaePercentage > 0.8 }
            if !algaeDeaths.isEmpty {
                return "Some corals were smothered by algae. Young corals need regular brushing until they're strong enough to attract helper fish."
            }
            return "Some corals didn't survive the pests. Snails and starfish eat coral tissue — remove them before the damage is done."
        }
        if !grew.isEmpty {
            return "Your reef matured! Adult corals now attract fish that clean algae and eat pests for you. A healthy reef takes care of itself."
        }
        let avgAlgae = afterLiving.map(\.algaePercentage).reduce(0, +) / Double(max(afterLiving.count, 1))
        if avgAlgae > 0.5 {
            return "Algae is winning. Without brushing, it blocks the light your corals need to grow."
        }
        return "Your reef held steady. Plant a mix of species — diverse reefs recover from shocks that wipe out monocultures."
    }

    // MARK: Tick (DEC-027)

    /// One live month: engine step + pest spawning. Driven by the view's timer so
    /// ticking only happens while the Coral Screen is visible.
    ///
    /// The reef is **paused during the guided cold open** (DEC-009): until the
    /// survivor frag is planted, nothing grows, accrues algae, spawns pests, or
    /// dies. The tutorial must be safe — a coral that can die before the player
    /// has learned to care for it teaches the wrong lesson.
    public func tickLive() {
        guard canvas?.guidedPlantDone == true else { return }
        tick()
        spawnPestsIfNeeded()
    }
}

/// Model → domain projection for hit-testing and interaction routing.
/// The simulation adapter is `SandboxViewModel.snapshot()` (DEC-020); this is
/// geometry-only.
extension CoralFrag {
    var snapshotForInteraction: CoralState {
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
