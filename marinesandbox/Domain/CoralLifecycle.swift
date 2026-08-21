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

    public static let babyEnd = 0.3
    public static let teenagerEnd = 0.7
    public static let adultEnd = 1.0
    public static let babyStartFrame: Double = 0
    public static let teenagerStartFrame: Double = 20
    public static let adultStartFrame: Double = 40
    public static let finalFrame: Double = 59

    public static func frame(for growthProgress: Double) -> Double {
        let progress = min(max(growthProgress, 0), adultEnd)
        switch progress {
        case ..<babyEnd:
            return teenagerStartFrame * progress / babyEnd
        case ..<teenagerEnd:
            return teenagerStartFrame + (adultStartFrame - teenagerStartFrame) * (progress - babyEnd) / (teenagerEnd - babyEnd)
        default:
            return adultStartFrame + (finalFrame - adultStartFrame) * (progress - teenagerEnd) / (adultEnd - teenagerEnd)
        }
    }

    public static func nextPhaseProgress(after growthProgress: Double) -> Double {
        switch min(max(growthProgress, 0), adultEnd) {
        case ..<babyEnd: babyEnd
        case ..<teenagerEnd: teenagerEnd
        default: adultEnd
        }
    }

    public static func orientation(for id: UUID) -> Orientation {
        id.uuid.0.isMultiple(of: 2) ? .left : .right
    }
}
