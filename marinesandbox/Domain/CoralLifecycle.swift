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
        let u = id.uuid
        let sum = Int(u.0) ^ Int(u.2) ^ Int(u.4) ^ Int(u.6) ^ Int(u.8) ^ Int(u.10) ^ Int(u.12) ^ Int(u.14)
        return sum % 2 == 0 ? .left : .right
    }

    public static func theme(for id: UUID) -> String {
        let themes = ["pink", "purple", "yellow"]
        let u = id.uuid
        let sum = Int(u.1) ^ Int(u.3) ^ Int(u.5) ^ Int(u.7) ^ Int(u.9) ^ Int(u.11) ^ Int(u.13) ^ Int(u.15)
        return themes[abs(sum) % themes.count]
    }
}
