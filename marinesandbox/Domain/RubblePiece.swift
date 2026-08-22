import CoreGraphics
import Foundation

/// A single dead coral rubble fragment in the cold-open rubble pile (DEC-009).
public struct RubblePiece: Identifiable, Sendable {
    public let id: UUID
    public let assetName: String
    public var offset: CGPoint
    public var rotation: Double
    public var isFlicked: Bool
    public var flickTargetOffset: CGPoint
    public var isCleared: Bool

    public init(
        id: UUID = UUID(),
        assetName: String,
        offset: CGPoint,
        rotation: Double,
        isFlicked: Bool = false,
        flickTargetOffset: CGPoint = .zero,
        isCleared: Bool = false
    ) {
        self.id = id
        self.assetName = assetName
        self.offset = offset
        self.rotation = rotation
        self.isFlicked = isFlicked
        self.flickTargetOffset = flickTargetOffset
        self.isCleared = isCleared
    }
}
