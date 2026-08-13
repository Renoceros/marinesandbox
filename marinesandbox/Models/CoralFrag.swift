import Foundation
import SwiftData

@Model
public final class CoralFrag {
    public var species: String // "Acropora" (Staghorn), "BrainCoral" (Massive), etc.
    public var growthProgress: Double // 0.0 (Baby) to 1.0 (Mature Adult)
    public var algaePercentage: Double // 0.0 (Clean) to 1.0 (Fully Smothered)
    public var predatorDamage: Double // 0.0 (None) to 1.0 (Fully Consumed)
    public var activePredators: [String] // ["CrownOfThorns", "DrupellaSnail", "Flatworm"]
    public var isBleached: Bool
    public var isDead: Bool
    
    // Computed helper variables for growth stages
    public var isBaby: Bool { growthProgress < 0.3 && !isDead }
    public var isTeenager: Bool { growthProgress >= 0.3 && growthProgress < 0.7 && !isDead }
    public var isAdult: Bool { growthProgress >= 0.7 && !isDead }
    
    public init(
        species: String,
        growthProgress: Double = 0.0,
        algaePercentage: Double = 0.0,
        predatorDamage: Double = 0.0,
        activePredators: [String] = [],
        isBleached: Bool = false,
        isDead: Bool = false
    ) {
        self.species = species
        self.growthProgress = growthProgress
        self.algaePercentage = algaePercentage
        self.predatorDamage = predatorDamage
        self.activePredators = activePredators
        self.isBleached = isBleached
        self.isDead = isDead
    }
}
