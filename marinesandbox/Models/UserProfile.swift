import Foundation
import SwiftData

@Model
public final class UserProfile {
    @Attribute(.unique) public var id: UUID
    public var currentSaveDate: Date
    public var unlockedCosmetics: [String] // List of unlocked skin IDs from QR codes
    public var activeCanvas: ReefCanvas?
    
    public init(id: UUID = UUID(), currentSaveDate: Date = Date(), unlockedCosmetics: [String] = []) {
        self.id = id
        self.currentSaveDate = currentSaveDate
        self.unlockedCosmetics = unlockedCosmetics
    }
}
