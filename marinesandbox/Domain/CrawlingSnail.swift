import CoreGraphics
import Foundation

/// An off-screen spawned snail crawling toward its target coral (DEC-034).
public struct CrawlingSnail: Identifiable, Sendable {
    public let id: UUID
    public let targetFragID: UUID
    public var currentX: Double
    public var startX: Double
    public var targetX: Double
    public var targetY: Double
    public var progress: Double // 0.0 -> 1.0
    public var isArrived: Bool

    public init(
        id: UUID = UUID(),
        targetFragID: UUID,
        startX: Double,
        targetX: Double,
        targetY: Double,
        progress: Double = 0.0,
        isArrived: Bool = false
    ) {
        self.id = id
        self.targetFragID = targetFragID
        self.startX = startX
        self.currentX = startX
        self.targetX = targetX
        self.targetY = targetY
        self.progress = progress
        self.isArrived = isArrived
    }
}
