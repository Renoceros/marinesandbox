import Foundation
import SwiftData

/// **CoralFrag: SwiftData Biological Entity Schema**
///
/// This persistent class represents a single planted coral fragment in the garden.
/// It tracks biological variables that feed directly into the math formulas of `EcoEngine`
/// and bind to visual states in the view layer.
///
/// ### Visual Bindings (Lottie Frame Scrubbing):
/// The visual presentation of coral uses playhead scrubbing mapped linearly to these fields:
/// - **Baby/Teenager Growth:** `growthProgress` $\in [0.0, 0.7)$ scrubs frames `0` to `42`.
/// - **Adult Growth:** `growthProgress` $\in [0.7, 1.0]$ scrubs frames `43` to `60`.
/// - **Thermal Bleaching:** `isBleached == true` transitions playhead to frames `61` to `80`.
/// - **Algae Overgrowth:** `algaePercentage` $\ge 0.5$ transitions playhead to frames `81` to `100`.
/// - **Death:** `isDead == true` freezes layout at frame `100` (barren gray rubble).
///
@Model
public final class CoralFrag {
    
    /// The specific species taxonomic identifier (e.g. `"Acropora"` for Staghorn, `"BrainCoral"` for massive).
    /// Used by `EcoEngine` to calculate Shannon diversity indices.
    public var species: String
    
    /// Continuous horizontal coordinate position ($x$-coordinate) along the scrollable seabed.
    /// Replacing the old PlacedStructure layout, this tracks the fragment's position directly on the seabed.
    public var xPos: Double
    
    /// Ratio representing coral growth, from `0.0` (freshly planted fragment) to `1.0` (mature adult colony).
    public var growthProgress: Double
    
    /// Ratio of structures covered by green/brown microalgae, from `0.0` (clean) to `1.0` (fully smothered).
    /// Brushing the screen reduces this value. High algae levels block light, halting growth.
    public var algaePercentage: Double
    
    /// Ratio of tissue consumed by coral predators, from `0.0` (no damage) to `1.0` (completely devoured skeleton).
    public var predatorDamage: Double
    
    /// List of active pests currently infesting the structure (e.g. `["DrupellaSnail"]`).
    /// Snails can be physically tapped or flicked off-screen to clear the list.
    public var activePredators: [String]
    
    /// Flag indicating if the coral is bleached (zooxanthellae expelled).
    /// Bleaching occurs during temperature spikes $> 30^\circ\text{C}$ and makes the coral highly vulnerable.
    public var isBleached: Bool
    
    /// Flag indicating if the coral has died. Once true, it displays as gray rubble.
    public var isDead: Bool
    
    // MARK: - Computed Growth Stage Helpers
    
    /// True if the coral is alive and in the initial growth phase.
    public var isBaby: Bool { growthProgress < 0.3 && !isDead }
    
    /// True if the coral is alive and in the intermediate growth phase.
    public var isTeenager: Bool { growthProgress >= 0.3 && growthProgress < 0.7 && !isDead }
    
    /// True if the coral is alive and has reached full maturity.
    /// Mature adult corals recruit grazing helper fish and pest control wrasses.
    public var isAdult: Bool { growthProgress >= 0.7 && !isDead }
    
    // MARK: - Initialization
    
    public init(
        species: String,
        xPos: Double = 0.0,
        growthProgress: Double = 0.0,
        algaePercentage: Double = 0.0,
        predatorDamage: Double = 0.0,
        activePredators: [String] = [],
        isBleached: Bool = false,
        isDead: Bool = false
    ) {
        self.species = species
        self.xPos = xPos
        self.growthProgress = growthProgress
        self.algaePercentage = algaePercentage
        self.predatorDamage = predatorDamage
        self.activePredators = activePredators
        self.isBleached = isBleached
        self.isDead = isDead
    }
}
