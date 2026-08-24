import UIKit

/// Haptic feedback service for tactile interactive gameplay (DEC-002, DEC-012).
@MainActor
public final class HapticService {
    public static let shared = HapticService()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private init() {
        prepare()
    }

    public func prepare() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        rigidImpact.prepare()
        notification.prepare()
        selection.prepare()
    }

    /// Triggers when smushing a snail with a tap (DEC-012).
    public func pestSmush() {
        mediumImpact.impactOccurred()
    }

    /// Triggers when flicking a snail off-screen with a swipe (DEC-012).
    public func pestFlick() {
        rigidImpact.impactOccurred()
    }

    /// Triggers when a fragment settles firmly into the seabed.
    public func plantSuccess() {
        notification.notificationOccurred(.success)
    }

    /// Triggers on tool selection switch.
    public func toolSelected() {
        selection.selectionChanged()
    }
}
