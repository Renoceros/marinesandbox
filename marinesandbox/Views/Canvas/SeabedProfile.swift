import CoreGraphics
import UIKit

/// **SeabedProfile: The Sand's Real Silhouette (TASK-MVP-102)**
///
/// Measures where the sand actually starts, column by column, by rasterising the
/// Foreground artwork and reading its alpha channel.
///
/// The seabed is not a straight line — each `FG` asset has a curved top edge, and
/// the three variants do not even share an aspect ratio (603×175.77, 603×173.93,
/// 603×186.57), so they render at different heights. Planting against a single
/// flat surface value left corals hovering wherever the sand dipped away and
/// buried where it rose.
///
/// Sampling the asset rather than hardcoding a curve is deliberate: every bug in
/// this area so far has been a constant drifting out of step with the artwork.
/// Swap the sand SVGs and this follows them.
///
@MainActor
final class SeabedProfile {

    static let shared = SeabedProfile()

    /// Columns sampled per variant. Fine enough to follow the curve, cheap
    /// enough to compute once at launch.
    private static let sampleCount = 256

    /// Alpha above which a pixel counts as sand rather than open water.
    private static let opaqueThreshold: UInt8 = 128

    private struct Sampled {
        /// Top of the sand per column, as a fraction of image height (0 = the
        /// sand reaches the very top of the artwork).
        let topFractions: [Double]
        /// height / width, so a rendered height can be derived from a width.
        let aspectRatio: Double
    }

    private var cache: [Int: Sampled] = [:]

    /// Height of the sand above the container floor at `layerX`, for a seabed
    /// laid out in blocks `blockWidth` wide.
    ///
    /// Returns nil until the artwork can be measured, so callers can fall back
    /// rather than plant a coral against a guess.
    func surfaceHeight(atLayerX layerX: CGFloat, blockWidth: CGFloat) -> Double? {
        let column = ParallaxMetrics.seabedColumn(layerX: layerX, blockWidth: blockWidth)
        guard let sampled = profile(forVariant: column.variant) else { return nil }

        let index = min(
            sampled.topFractions.count - 1,
            max(0, Int(column.localFraction * CGFloat(sampled.topFractions.count)))
        )
        let renderedHeight = Double(blockWidth) * sampled.aspectRatio
        return ParallaxMetrics.surfaceHeight(
            topFraction: sampled.topFractions[index],
            renderedHeight: renderedHeight
        )
    }

    // MARK: - Sampling

    private func profile(forVariant variant: Int) -> Sampled? {
        if let cached = cache[variant] { return cached }
        guard let sampled = sample(variant: variant) else { return nil }
        cache[variant] = sampled
        return sampled
    }

    private func sample(variant: Int) -> Sampled? {
        guard let image = UIImage(named: "FG\(variant)")?.cgImage else { return nil }

        let width = image.width, height = image.height
        guard width > 0, height > 0 else { return nil }

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var topFractions: [Double] = []
        topFractions.reserveCapacity(Self.sampleCount)

        for sample in 0..<Self.sampleCount {
            let x = min(width - 1, sample * width / Self.sampleCount)
            var top = 1.0 // no sand in this column at all
            for y in 0..<height {
                let alpha = pixels[(y * width + x) * 4 + 3]
                if alpha >= Self.opaqueThreshold {
                    top = Double(y) / Double(height)
                    break
                }
            }
            topFractions.append(top)
        }

        return Sampled(
            topFractions: topFractions,
            aspectRatio: Double(height) / Double(width)
        )
    }
}
