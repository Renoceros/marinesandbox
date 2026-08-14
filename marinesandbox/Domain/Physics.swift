import CoreGraphics
import Foundation

/// **Physics: Simplified 2D Drag & Flick Dynamics (TASK-MVP-104)**
///
/// Pure, deterministic motion helpers for the two tactile gestures:
/// dragging coral frags onto the seabed and flicking pests off-screen (DEC-012).
/// No SwiftUI, no SwiftData — the view feeds gesture samples in and renders
/// whatever comes out, which keeps this layer unit-testable from the sidecar
/// package (DEC-022).
///
public enum Physics {

    // MARK: - Pest Flicking

    /// Release speed (points/second) above which a pest is thrown off-screen.
    /// Below the threshold the gesture reads as a tap — the pest is smushed
    /// instead of flicked (DEC-012).
    public static let flickThreshold: Double = 100.0

    /// Gravity for thrown pests, tuned for feel rather than realism (pt/s²).
    public static let throwGravity: Double = 2000.0

    /// Whether a release velocity throws the pest.
    public static func isFlick(velocity: CGPoint) -> Bool {
        (velocity.x * velocity.x + velocity.y * velocity.y).squareRoot() > flickThreshold
    }

    /// Ballistic position of a thrown pest at `time` seconds after release.
    public static func throwPosition(from origin: CGPoint, velocity: CGPoint, at time: Double) -> CGPoint {
        CGPoint(
            x: origin.x + velocity.x * time,
            y: origin.y + velocity.y * time + 0.5 * throwGravity * time * time
        )
    }

    /// The first sampled time at which a thrown pest leaves the viewport, stepping at
    /// `dt`. Used to drive the despawn animation; `nil` if still inside after `limit`.
    public static func despawnTime(
        from origin: CGPoint,
        velocity: CGPoint,
        viewport: CGRect,
        dt: Double = 1.0 / 60.0,
        limit: Double = 5.0
    ) -> Double? {
        var t = dt
        while t <= limit {
            if !viewport.contains(throwPosition(from: origin, velocity: velocity, at: t)) {
                return t
            }
            t += dt
        }
        return nil
    }

    // MARK: - Frag Dragging & Planting

    /// Converts a screen-space drag point into canvas coordinates by adding the
    /// parallax scroll offset (DEC-021: `scrollX` is owned by `SandboxViewModel`).
    public static func canvasPoint(fromScreenPoint point: CGPoint, scrollX: Double) -> CGPoint {
        CGPoint(x: point.x - scrollX, y: point.y)
    }

    /// Clamps a drop position to the playable seabed bounds (DEBT-001: the world is
    /// bounded at 4.5× viewport width, so the foreground must be clamped).
    public static func clampedDrop(
        _ point: CGPoint,
        canvasWidth: Double,
        margin: Double = 20.0
    ) -> CGPoint {
        CGPoint(
            x: min(max(point.x, margin), canvasWidth - margin),
            y: max(point.y, 0)
        )
    }
}
