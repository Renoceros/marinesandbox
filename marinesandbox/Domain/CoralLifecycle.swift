import Foundation

public enum CoralLifecycle {
    public enum Orientation: Sendable {
        case left
        case right

        public var assetName: String {
            switch self {
            case .left: "coral_lh"
            case .right: "coral"
            }
        }
    }

    public static let fragmentFrame: Double = 0
    public static let babyFrame: Double = 15
    public static let toddlerFrame: Double = 30
    public static let teenagerFrame: Double = 45
    public static let adultFrame: Double = 59

    public static let babyEnd = 0.25
    public static let toddlerEnd = 0.50
    public static let teenagerEnd = 0.75
    public static let adultEnd = 1.0

    public static func frame(for growthProgress: Double) -> Double {
        let progress = min(max(growthProgress, 0), adultEnd)
        return progress * adultFrame
    }

    public static func nextPhaseProgress(after growthProgress: Double) -> Double {
        switch min(max(growthProgress, 0), adultEnd) {
        case ..<babyEnd: babyEnd
        case ..<toddlerEnd: toddlerEnd
        case ..<teenagerEnd: teenagerEnd
        default: adultEnd
        }
    }

    public static func orientation(for id: UUID) -> Orientation {
        id.uuid.0.isMultiple(of: 2) ? .left : .right
    }
}
