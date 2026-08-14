import CoreGraphics
import Foundation

/// **CoralGeometry: Model-Space Sizes & Asset Registry (DEC-019)**
///
/// Hit-testing runs against **model geometry, never artwork bounds** (DEC-019).
/// This registry is that geometry: the size of a coral at each growth stage,
/// derived from the viewBox of Sam's SVG assets, anchored bottom-center so the
/// base stays planted on the seabed as the sprite grows.
///
/// The same table maps stages to asset catalog names, so the placeholder/skeleton
/// renderer and any later Lottie provider (DEC-017) swap behind one seam.
///
public enum CoralGeometry {

    /// A stage's rendered footprint in points, plus its current asset.
    public struct Footprint: Equatable, Sendable {
        public let assetName: String
        public let size: CGSize

        public init(assetName: String, size: CGSize) {
            self.assetName = assetName
            self.size = size
        }
    }

    /// Footprints per growth stage, from the asset viewBoxes:
    /// fragment 59.89×181.77 · toddler 106.67×159.16 · teen 162.56×193.60 · adult 193.21×243.32.
    /// Baby renders as a planted fragment; the teenager band interpolates between
    /// the toddler and teen sprites; adults use the adult sprite.
    public static func footprint(for coral: CoralState) -> Footprint {
        switch coral.stage {
        case .baby:
            return Footprint(assetName: "Fragment1", size: CGSize(width: 59.89, height: 181.77))
        case .teenager:
            // Interpolate within the band: early teen reads as toddler, late teen as teen.
            return coral.growthProgress < 0.5
                ? Footprint(assetName: "CoralToddler", size: CGSize(width: 106.67, height: 159.16))
                : Footprint(assetName: "CoralTeen", size: CGSize(width: 162.56, height: 193.60))
        case .adult:
            return Footprint(assetName: "CoralAdult", size: CGSize(width: 193.21, height: 243.32))
        }
    }

    /// The seabed-anchored bounding box of a coral in canvas space (y measured down
    /// from the top, matching screen space at `scrollX == 0`). The sprite's base sits
    /// `yPos` points above the `seabedY` baseline, bottom-center anchored at `xPos`.
    /// All hit-tests (tap-to-select, brush strokes, pest taps) run against this rect.
    public static func hitRect(for coral: CoralState, seabedY: Double) -> CGRect {
        let footprint = footprint(for: coral)
        return CGRect(
            x: coral.xPos - footprint.size.width / 2,
            y: seabedY - coral.yPos - footprint.size.height,
            width: footprint.size.width,
            height: footprint.size.height
        )
    }

    /// The first coral whose hit rect contains a canvas-space point, front-most
    /// (last planted) wins when sprites overlap.
    public static func hitTest(corals: [CoralState], at point: CGPoint, seabedY: Double) -> CoralState? {
        corals.last { !$0.isDead && hitRect(for: $0, seabedY: seabedY).contains(point) }
    }

    /// Converts a canvas-space point into normalised coral-local space for the
    /// algae grid (DEC-018): (0,0) top-left of the coral's box, (1,1) bottom-right.
    /// Returns `nil` when the point misses the coral entirely.
    public static func localPoint(in coral: CoralState, canvasPoint: CGPoint, seabedY: Double) -> CGPoint? {
        let rect = hitRect(for: coral, seabedY: seabedY)
        guard rect.contains(canvasPoint) else { return nil }
        return CGPoint(
            x: (canvasPoint.x - rect.minX) / rect.width,
            y: (canvasPoint.y - rect.minY) / rect.height
        )
    }
}
