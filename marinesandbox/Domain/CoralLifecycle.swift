import Foundation

public enum CoralLifecycle {
    public enum Orientation: Sendable {
        case left
        case right

        public var assetName: String {
            switch self {
            case .left: "staghorn_coral_lh"
            case .right: "staghorn_coral_rh"
            }
        }
    }

    public static let babyEnd = 0.25
    public static let toddlerEnd = 0.50
    public static let teenagerEnd = 0.75
    public static let adultEnd = 1.0

    public static func assetName(species: String, id: UUID) -> String {
        switch species {
        case "BrainCoral":
            return "brain_coral"
        default:
            return orientation(for: id).assetName
        }
    }

    public static func totalFrames(species: String) -> Double {
        switch species {
        case "BrainCoral":
            return 599.0
        default:
            return 59.0
        }
    }

    public static func frame(for growthProgress: Double, species: String) -> Double {
        let progress = min(max(growthProgress, 0), adultEnd)
        return progress * totalFrames(species: species)
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
