import Foundation
import SwiftData

@Model
public final class ReefCanvas {
    @Attribute(.unique) public var id: UUID
    public var ngoRegion: String // "Bali", "Jeju", "Caribbean"
    public var canvasWidth: Double // Total horizontal scroll width
    @Relationship(deleteRule: .cascade) public var placedStructures: [PlacedStructure]
    
    public init(id: UUID = UUID(), ngoRegion: String, canvasWidth: Double = 2000.0, placedStructures: [PlacedStructure] = []) {
        self.id = id
        self.ngoRegion = ngoRegion
        self.canvasWidth = canvasWidth
        self.placedStructures = placedStructures
    }
}
