import Foundation
import SwiftData

/// **ReefCanvas: SwiftData Persisted Active Sandbox Schema**
///
/// This persistent model represents the active garden canvas sandbox.
/// It coordinates the horizontal layout limits and tracks placed structure elements.
///
/// ### Architectural Decoupling:
/// As requested, **`locationType` has been removed** from the schema constraints.
/// Users are no longer restricted to environmental sub-zones (like "Shallow Reef Flat" vs "Deep Wall Slope")
/// which would limit growth speeds or enforce one-size-fits-all parameters.
/// Instead, players can freely construct biodiverse gardens anywhere along the continuous horizontal landscape.
///
@Model
public final class ReefCanvas {
    
    /// Unique identifier for the canvas layout.
    @Attribute(.unique) public var id: UUID
    
    /// The primary NGO region selection (e.g. `"Bali"` / Living Seas default).
    public var ngoRegion: String
    
    /// Total horizontal content width bounds in points.
    /// This supports the parallax scrolling range limit.
    public var canvasWidth: Double
    
    /// Array of coral fragments planted along the canvas.
    /// Cascades deletions when the canvas is cleared.
    @Relationship(deleteRule: .cascade) public var coralFrags: [CoralFrag]

    /// Whether the guided first plant (DEC-009/024) has been completed.
    /// Persisted so an interrupted cold open resumes the guide on next launch.
    public var guidedPlantDone: Bool
    
    /// Initializes a new ReefCanvas instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - ngoRegion: Standard region name selector.
    ///   - canvasWidth: Horizontal boundary length (points).
    ///   - coralFrags: Living coral fragments list.
    ///
    public init(
        id: UUID = UUID(),
        ngoRegion: String,
        canvasWidth: Double = 2000.0,
        coralFrags: [CoralFrag] = [],
        guidedPlantDone: Bool = false
    ) {
        self.id = id
        self.ngoRegion = ngoRegion
        self.canvasWidth = canvasWidth
        self.coralFrags = coralFrags
        self.guidedPlantDone = guidedPlantDone
    }
}
