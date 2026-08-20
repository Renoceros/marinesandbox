import Foundation
import SwiftData

/// **CoralFrag: SwiftData Biological Entity Schema**
///
/// This persistent class represents a single planted coral fragment in the garden.
/// It is the persistence twin of the domain's `CoralState` value snapshot (DEC-020) —
/// `SandboxViewModel` maps between the two, matching on `id`.
///
/// ### Visual Bindings (DEC-018 layered compositions):
/// The visual presentation is composited from separate Lottie files, not a single
/// scrubbed playhead:
/// - **Growth body:** playhead scrubbed to `growthProgress` (markers `baby`/`teen`/`adult`).
/// - **Algae overlay:** looping composition, masked per-cell by `algaeCells` (the 6×6
///   `AlgaeCoverage` grid). Coverage is spatial — a scalar playhead cannot express
///   *where* the dirt is, so the grid is persisted and `algaePercentage` is derived.
/// - **Death:** `isDead == true` renders as barren gray rubble.
///
@Model
public final class CoralFrag {

    /// Stable identity shared with the domain's `CoralState.id`, so snapshot ↔ model
    /// round trips never lose track of which fragment is which (DEC-020 adapter).
    @Attribute(.unique) public var id: UUID

    /// The specific species taxonomic identifier (e.g. `"Acropora"` for Staghorn, `"BrainCoral"` for massive).
    /// Used by `EcoEngine` to calculate Shannon diversity indices.
    public var species: String

    /// Continuous horizontal coordinate position ($x$-coordinate) along the scrollable seabed.
    public var xPos: Double

    /// Continuous vertical coordinate position ($y$-coordinate) along the scrollable seabed.
    /// Supports vertical placement for species like fan corals perched on boulders or vertical reef walls.
    public var yPos: Double

    /// Ratio representing coral growth, from `0.0` (freshly planted fragment) to `1.0` (mature adult colony).
    /// Accumulates *effective* healthy time, not wall time — algae and pest slowdown
    /// modifiers (DEC-031) make a neglected coral take longer than 7 days to mature.
    public var growthProgress: Double

    /// Wall-clock moment this fragment was planted (DEC-031). Anchors the 7-day
    /// lifecycle and the per-coral age. Growth does not advance during the guided
    /// cold open (DEC-009), so the survivor's clock effectively starts when ticks begin.
    public var plantedAt: Date

    /// Row-major 6×6 algae coverage grid (see `AlgaeCoverage` in the domain layer, DEC-018).
    /// Each cell is `0.0` (clean) to `1.0` (fully smothered). Brushing clears the cells a
    /// stroke crosses; helper-fish grazing thins the thickest cells first.
    public var algaeCells: [Float]

    /// Ratio of tissue consumed by coral predators, from `0.0` (no damage) to `1.0` (completely devoured skeleton).
    public var predatorDamage: Double

    /// List of active pests currently infesting the fragment (e.g. `["DrupellaSnail"]`).
    /// Snails can be physically tapped or flicked off-screen to clear the list.
    public var activePredators: [String]

    /// Flag indicating if the coral is bleached (zooxanthellae expelled).
    /// Dormant in the exhibition build — no threat vector ever triggers it (DEC-025).
    public var isBleached: Bool

    /// Flag indicating if the coral has died. Once true, it displays as gray rubble.
    public var isDead: Bool

    // MARK: - Derived State

    /// Aggregate algae coverage, derived from the spatial grid (`AlgaeCoverage.percentage`).
    public var algaePercentage: Double {
        guard !algaeCells.isEmpty else { return 0.0 }
        return algaeCells.map(Double.init).reduce(0, +) / Double(algaeCells.count)
    }

    /// True if the coral is alive and in the initial growth phase.
    public var isBaby: Bool { growthProgress < 0.3 && !isDead }

    /// True if the coral is alive and in the intermediate growth phase.
    public var isTeenager: Bool { growthProgress >= 0.3 && growthProgress < 0.7 && !isDead }

    /// True if the coral is alive and has reached full maturity.
    /// Mature adult corals recruit grazing helper fish and pest control wrasses.
    public var isAdult: Bool { growthProgress >= 0.7 && !isDead }

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        species: String,
        xPos: Double = 0.0,
        yPos: Double = 0.0,
        growthProgress: Double = 0.0,
        plantedAt: Date = Date(),
        algaeCells: [Float] = [],
        predatorDamage: Double = 0.0,
        activePredators: [String] = [],
        isBleached: Bool = false,
        isDead: Bool = false
    ) {
        self.id = id
        self.species = species
        self.xPos = xPos
        self.yPos = yPos
        self.growthProgress = growthProgress
        self.plantedAt = plantedAt
        self.algaeCells = algaeCells
        self.predatorDamage = predatorDamage
        self.activePredators = activePredators
        self.isBleached = isBleached
        self.isDead = isDead
    }
}
