import CoreGraphics
import Foundation

/// **ParallaxMetrics: Seabed Geometry (TASK-MVP-102)**
///
/// The single source of truth for how far the seabed moves and how wide the
/// reachable reef is. Corals are planted *in* the Foreground (sand) layer, so
/// the entity layer in `SandboxView` and the Foreground layer in
/// `ParallaxScrollView` must scale by the exact same ratio. When they disagreed
/// — the layer at 0.20, the corals at an implicit 1.0 — the reef slid across
/// the sand at five times the sand's own speed. One constant, one home.
///
/// Pure CoreGraphics, no SwiftUI, so it stays unit-testable from the sidecar
/// package (DEC-022).
///
public enum ParallaxMetrics {

    // MARK: - Constants

    /// Drag range as a multiple of viewport width. Spec (TASK-MVP-102): the
    /// scroll offset is clamped to `[-3.5 * viewportWidth, 0]`.
    public static let panRangeFactor: CGFloat = 3.5

    /// The Foreground (seabed) layer's parallax ratio.
    ///
    /// Anything that renders *on the sand* — corals, the guided-plant pulse,
    /// the frag drag preview — must translate by this ratio, not by the raw
    /// scroll offset. Retuning the Foreground layer means retuning this, and
    /// `ParallaxMetricsTests` will catch the two drifting apart.
    public static let seabedRatio: CGFloat = 0.20

    /// The seabed artwork's width as a multiple of viewport width.
    public static let seabedWidthScale: CGFloat = 1.5

    // MARK: - Derived Geometry

    /// Total horizontal distance the user can drag, in points.
    public static func panRange(viewportWidth: CGFloat) -> CGFloat {
        viewportWidth * panRangeFactor
    }

    /// How far the seabed (and everything planted in it) has translated for a
    /// given scroll offset.
    ///
    /// Deliberately unclamped: during rubber-band overscroll the binding runs
    /// past its bounds, and the corals should stretch along with the world
    /// rather than detach from the sand at the edges.
    public static func seabedOffset(scrollX: CGFloat) -> CGFloat {
        scrollX * seabedRatio
    }

    /// Width of the reachable reef, in seabed-local points.
    ///
    /// The seabed only travels `panRange * seabedRatio` — a fraction of the
    /// full drag range — so the playable strip is one viewport plus that
    /// travel. Sizing the reef to the full pan range instead would strand
    /// every coral planted beyond the sand's reach.
    public static func playableWidth(viewportWidth: CGFloat) -> CGFloat {
        viewportWidth + panRange(viewportWidth: viewportWidth) * seabedRatio
    }

    // MARK: - Which Sand Is Under A Given X

    /// Slot in a column's permutation that the Foreground (seabed) layer draws
    /// from. Shared with `ParallaxScrollView` so the renderer and the planting
    /// logic can never disagree about which sand sits where.
    public static let seabedVariantSlot = 2

    /// Deterministic permutation of the three artwork variants for a column.
    public static func permutation(col: Int) -> [Int] {
        let permutations = [
            [0, 1, 2], [0, 2, 1], [1, 0, 2],
            [1, 2, 0], [2, 0, 1], [2, 1, 0]
        ]
        let hash = abs((col ^ 1001) &* 324159265) % 6
        return permutations[hash]
    }

    /// Which seabed variant sits under `layerX`, and how far across that block
    /// the point falls.
    ///
    /// `layerX` is a coral's `xPos`. Corals and the seabed translate by the same
    /// `seabedOffset`, so a coral's stored x already *is* its position in the
    /// sand strip — no parallax term belongs here.
    public static func seabedColumn(
        layerX: CGFloat,
        blockWidth: CGFloat
    ) -> (variant: Int, localFraction: CGFloat) {
        guard blockWidth > 0 else { return (permutation(col: 0)[seabedVariantSlot], 0) }
        let col = Int(floor(layerX / blockWidth))
        var local = (layerX - CGFloat(col) * blockWidth) / blockWidth
        local = min(max(local, 0), 0.999999) // overscroll can nudge this out of range
        return (permutation(col: col)[seabedVariantSlot], local)
    }

    // MARK: - Resting On The Sand

    /// How far a frag beds into the sand once it lands, so it reads as planted
    /// rather than balanced on the silhouette.
    public static let seabedEmbedDepth: Double = 10.0

    /// Height of the sand at one column position, given where the artwork's
    /// silhouette starts.
    ///
    /// `topFraction` is the sampled top of the sand as a fraction of the image
    /// height, so the sand occupies everything below it.
    public static func surfaceHeight(topFraction: Double, renderedHeight: Double) -> Double {
        max(0, renderedHeight * (1 - min(max(topFraction, 0), 1)))
    }

    /// Where a frag released at `dropHeight` above the container floor rests.
    ///
    /// The seabed is not a straight line — the artwork rises and dips across its
    /// width — so the ceiling here is the sand height *at that coral's x*, not a
    /// single flat value. A frag dropped from open water beds into the sand it
    /// actually lands on; one already placed lower inside the sand keeps its own
    /// depth.
    public static func restingHeight(
        dropHeight: Double,
        surfaceHeight: Double,
        embedDepth: Double = seabedEmbedDepth
    ) -> Double {
        let bedded = surfaceHeight - embedDepth
        return max(0, min(dropHeight, bedded))
    }
}
