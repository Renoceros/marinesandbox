import Foundation
import SwiftData

@Model
public final class PlacedStructure {
    @Attribute(.unique) public var id: UUID
    public var xPos: Double // Continuous horizontal offset on the seabed
    public var structureType: String // "ReefStar", "Bottle"
    @Relationship(deleteRule: .cascade) public var coral: CoralFrag?
    
    public init(id: UUID = UUID(), xPos: Double, structureType: String, coral: CoralFrag? = nil) {
        self.id = id
        self.xPos = xPos
        self.structureType = structureType
        self.coral = coral
    }
}
