import Foundation
import SwiftData

/// **PlacedStructure: SwiftData Schema for Deployed Infrastructure**
///
/// This persistent model represents a physical structure (e.g. a metal Reef Star frame
/// or concrete anchor) placed by the user on the seabed.
///
/// ### Continuous Coordinates:
/// Rather than using discrete grid cells, structures are positioned along a continuous
/// horizontal axis using an arbitrary coordinate offset (`xPos`). This layout scrolls
/// in lockstep with the foreground layer of the parallax scrolling view (ratio `1.00`).
///
@Model
public final class PlacedStructure {
    
    /// Unique identifier for the placed structure.
    @Attribute(.unique) public var id: UUID
    
    /// Continuous horizontal coordinate position ($x$-coordinate) along the scrollable seabed.
    public var xPos: Double
    
    /// The physical structure type (e.g. `"ReefStar"` or `"Bottle"`).
    public var structureType: String
    
    /// The biological coral fragment planted on this structure.
    /// Cascades deletion to prevent orphaned coral frag models in the database.
    @Relationship(deleteRule: .cascade) public var coral: CoralFrag?
    
    /// Initializes a new PlacedStructure instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - xPos: Continuous horizontal offset.
    ///   - structureType: Type of structure deployed.
    ///   - coral: Coral fragment initially planted (nil if empty frame).
    ///
    public init(
        id: UUID = UUID(),
        xPos: Double,
        structureType: String,
        coral: CoralFrag? = nil
    ) {
        self.id = id
        self.xPos = xPos
        self.structureType = structureType
        self.coral = coral
    }
}
