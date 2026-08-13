import Foundation
import SwiftData

/// **UserProfile: SwiftData Schema for Profile & Customizations**
///
/// This persistent model represents the local user account profile.
/// It tracks active progress and unlocked cosmetics (skins, badges) rewarded
/// from field-based QR scans or achievements.
///
/// ### Apple Sign-In Integration:
/// As decided in the team discussions, user account registration is designed around
/// **Apple Sign-In** (Face ID verification) instead of Passkeys. This provides a direct,
/// secure mapping of user emails to their unique persistent profile IDs in the database,
/// making sync transitions straightforward.
///
@Model
public final class UserProfile {
    
    /// Unique profile identifier linked to the authenticated Apple user ID.
    @Attribute(.unique) public var id: UUID
    
    /// Timestamp of the last local save synchronization.
    public var currentSaveDate: Date
    
    /// List of cosmetic skin IDs or badge identifiers unlocked via achievements or scan codes.
    public var unlockedCosmetics: [String]
    
    /// Relationship to the user's active sandbox canvas.
    public var activeCanvas: ReefCanvas?
    
    /// Initializes a new UserProfile instance.
    ///
    /// - Parameters:
    ///   - id: Unique profile ID.
    ///   - currentSaveDate: Last modified date.
    ///   - unlockedCosmetics: List of unlocked cosmetic skin IDs.
    ///
    public init(
        id: UUID = UUID(),
        currentSaveDate: Date = Date(),
        unlockedCosmetics: [String] = []
    ) {
        self.id = id
        self.currentSaveDate = currentSaveDate
        self.unlockedCosmetics = unlockedCosmetics
    }
}
