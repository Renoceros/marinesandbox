import Foundation

/// **ThreatVector: Environmental Shocks and Stressors**
///
/// Encapsulates the active environmental stress factors passed to the stateless `EcoEngine`.
/// These variables simulate global heating spikes, temperature waves, and land-based runoff
/// that influence coral growth rates, algae coverage, and bleaching states.
///
public struct ThreatVector {
    
    /// Triggered by agricultural runoff or heavy rains.
    /// When true, it multiplies the baseline algae growth rate by $\times 2.5$.
    public var agriculturalRunoff: Bool
    
    /// Flag indicating if an active Marine Heatwave event is underway.
    /// Affects whether bleached corals are allowed to recover after temperatures drop.
    public var isHeatwaveActive: Bool
    
    /// Current ambient water temperature in Celsius.
    /// Water temperatures $> 30.0^\circ\text{C}$ trigger coral bleaching (ejection of zooxanthellae).
    /// Standard baseline temperature is $27.0^\circ\text{C}$.
    public var waterTemperature: Double
    
    /// Initializes a new ThreatVector instance.
    ///
    /// - Parameters:
    ///   - agriculturalRunoff: Toggles land-based nutrient pollution.
    ///   - isHeatwaveActive: Toggles global heatwave status.
    ///   - waterTemperature: Ambient water temperature (Celsius).
    ///
    public init(
        agriculturalRunoff: Bool = false,
        isHeatwaveActive: Bool = false,
        waterTemperature: Double = 27.0
    ) {
        self.agriculturalRunoff = agriculturalRunoff
        self.isHeatwaveActive = isHeatwaveActive
        self.waterTemperature = waterTemperature
    }
}
