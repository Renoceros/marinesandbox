import Foundation
import SwiftData

/// **NGOConfig: SwiftData Regional Environment Schema**
///
/// This persistent model holds the environmental preset for a partner NGO region.
/// The exhibition build ships exactly one config — **Bali / Living Seas** — as the
/// implicit default; Jeju and Caribbean remain roadmap config items and are never
/// a user-facing choice (DEC-003, DEC-008).
///
/// ### Exhibition Dormancy Enforcement (DEC-025):
/// `heatwaveAllowed` is the single switch that keeps `EcoEngine` section D dormant:
/// when `false`, session threat vectors are built with `waterTemperature <= 30°C`
/// and `isHeatwaveActive == false`, so bleaching can never trigger in gameplay.
///
@Model
public final class NGOConfig {

    /// Unique region identifier (e.g. `"Bali"`).
    @Attribute(.unique) public var regionName: String

    /// Species the user can plant in this region (e.g. `["Acropora", "BrainCoral"]`, PRD §4).
    public var availableSpecies: [String]

    /// Baseline water temperature in Celsius. Bleaching triggers above `30.0` (PRD §4.6).
    public var baselineTemperature: Double

    /// Whether agricultural runoff shocks can occur in this region.
    public var runoffShockAllowed: Bool

    /// Whether marine heatwave events can occur in this region.
    /// **MUST be `false` for the exhibition build** — this is the enforcement point
    /// for bleaching dormancy (DEC-025). The engine code stays; the threats never come.
    public var heatwaveAllowed: Bool

    /// Pest types that can appear in this region
    /// (e.g. `["DrupellaSnail", "CrownOfThornsStarfish"]`).
    public var pestCatalog: [String]

    /// Initializes a new NGOConfig instance.
    public init(
        regionName: String,
        availableSpecies: [String],
        baselineTemperature: Double,
        runoffShockAllowed: Bool,
        heatwaveAllowed: Bool,
        pestCatalog: [String]
    ) {
        self.regionName = regionName
        self.availableSpecies = availableSpecies
        self.baselineTemperature = baselineTemperature
        self.runoffShockAllowed = runoffShockAllowed
        self.heatwaveAllowed = heatwaveAllowed
        self.pestCatalog = pestCatalog
    }
}

extension NGOConfig {

    /// The exhibition default: Bali / Living Seas (DEC-003, DEC-008).
    ///
    /// `heatwaveAllowed` is `false` — bleaching is engine-supported but dormant
    /// until the post-exhibition prestige-restart loop (DEC-025).
    public static var exhibitionBali: NGOConfig {
        NGOConfig(
            regionName: "Bali",
            availableSpecies: ["Acropora", "BrainCoral"],
            baselineTemperature: 27.0,
            runoffShockAllowed: true,
            heatwaveAllowed: false, // DEC-025: do not flip without superseding that entry
            pestCatalog: ["DrupellaSnail", "CrownOfThornsStarfish"]
        )
    }
}
