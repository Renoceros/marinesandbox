import Foundation

/// **GrowthStage: Coral Maturity Bands**
///
/// Thresholds mirror the computed helpers on the `CoralFrag` SwiftData schema so the
/// domain and the persisted model can never disagree about what "teenager" means.
public enum GrowthStage: String, Sendable {
    case baby
    case teenager
    case adult

    public init(growthProgress: Double) {
        switch growthProgress {
        case ..<0.3: self = .baby
        case ..<0.7: self = .teenager
        default: self = .adult
        }
    }

    /// Baby and teenager colonies are the algae-vulnerable stages.
    public var isAlgaeVulnerable: Bool { self != .adult }
}

/// **CoralState: Value Snapshot of One Fragment**
///
/// The simulation twin of `CoralFrag`. Being a value type is the point: `EcoEngine` can
/// project years of growth without touching the database, so Fast Forward can *compute*
/// a steady state, show the timelapse, and only then commit (DEC-020).
public struct CoralState: Identifiable, Equatable, Sendable {

    public let id: UUID

    /// Taxonomic identifier, e.g. `"Acropora"` or `"BrainCoral"`. Feeds the Shannon index.
    public var species: String

    /// Continuous seabed coordinates. Corals are planted directly on the ground (DEC-024).
    public var xPos: Double
    public var yPos: Double

    /// `0.0` freshly planted fragment to `1.0` mature adult colony.
    public var growthProgress: Double

    /// Spatial algae model. The scalar the maths uses is derived from it (DEC-018).
    public var coverage: AlgaeCoverage

    /// `0.0` untouched to `1.0` tissue completely consumed.
    public var predatorDamage: Double

    /// Pests currently infesting this fragment, e.g. `["DrupellaSnail"]`.
    public var activePredators: [String]

    public var isBleached: Bool
    public var isDead: Bool

    public init(
        id: UUID = UUID(),
        species: String,
        xPos: Double = 0,
        yPos: Double = 0,
        growthProgress: Double = 0,
        coverage: AlgaeCoverage = AlgaeCoverage(),
        predatorDamage: Double = 0,
        activePredators: [String] = [],
        isBleached: Bool = false,
        isDead: Bool = false
    ) {
        self.id = id
        self.species = species
        self.xPos = xPos
        self.yPos = yPos
        self.growthProgress = growthProgress
        self.coverage = coverage
        self.predatorDamage = predatorDamage
        self.activePredators = activePredators
        self.isBleached = isBleached
        self.isDead = isDead
    }

    // MARK: - Derived State

    /// Aggregate algae coverage, derived from the spatial grid.
    public var algaePercentage: Double { coverage.percentage }

    public var stage: GrowthStage { GrowthStage(growthProgress: growthProgress) }

    public var isBaby: Bool { !isDead && stage == .baby }
    public var isTeenager: Bool { !isDead && stage == .teenager }
    public var isAdult: Bool { !isDead && stage == .adult }

    /// Adult colonies recruit the grazers and predators that automate care.
    public var recruitsHelpers: Bool { isAdult }
}

/// **ReefState: Value Snapshot of the Whole Canvas**
public struct ReefState: Equatable, Sendable {

    /// `"Bali"`, `"Jeju"`, `"Caribbean"`.
    public var ngoRegion: String

    /// Total horizontal scroll width of the seabed.
    public var canvasWidth: Double

    public var corals: [CoralState]

    public init(ngoRegion: String, canvasWidth: Double = 2000.0, corals: [CoralState] = []) {
        self.ngoRegion = ngoRegion
        self.canvasWidth = canvasWidth
        self.corals = corals
    }

    /// Living fragments — the only ones the ecology maths considers.
    public var livingCorals: [CoralState] { corals.filter { !$0.isDead } }
}
