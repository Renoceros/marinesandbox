import Testing
import Foundation
@testable import Domain

/// Pins the seabed geometry. Corals are planted *in* the Foreground layer, so
/// the entity layer and `ParallaxScrollView` must agree on one ratio — when they
/// disagreed, the reef slid across the sand at 5x the sand's own speed. These
/// tests exist so that disagreement can never come back silently.
@Suite("ParallaxMetrics")
struct ParallaxMetricsTests {

    // A stand-in for a typical iPhone viewport, used across the cases below.
    let viewport: CGFloat = 393.0

    // MARK: - Pan Range

    @Test func panRangeIsThreeAndAHalfViewports() {
        // Spec (TASK-MVP-102): scrollX is clamped to [-3.5 * viewportWidth, 0].
        let expected: CGFloat = 1375.5 // 393.0 * 3.5
        #expect(ParallaxMetrics.panRange(viewportWidth: viewport) == expected)
    }

    @Test func panRangeScalesWithViewport() {
        let expected: CGFloat = 3500.0
        #expect(ParallaxMetrics.panRange(viewportWidth: 1000) == expected)
    }

    // MARK: - Seabed Offset

    @Test func seabedOffsetScalesScrollByTheSeabedRatio() {
        // A coral must translate by exactly what the sand under it translates by.
        #expect(ParallaxMetrics.seabedOffset(scrollX: -1000) == -1000 * ParallaxMetrics.seabedRatio)
    }

    @Test func seabedOffsetIsZeroAtRest() {
        #expect(ParallaxMetrics.seabedOffset(scrollX: 0) == 0)
    }

    @Test func seabedOffsetFollowsOverscrollPastTheEdge() {
        // During rubber-band the binding goes positive; corals stretch with the
        // world rather than detaching from it, so no clamping happens here.
        #expect(ParallaxMetrics.seabedOffset(scrollX: 50) == 50 * ParallaxMetrics.seabedRatio)
    }

    // MARK: - Playable Width

    @Test func playableWidthCoversTheViewportPlusTheSeabedsOwnTravel() {
        // The seabed only travels `panRange * ratio`, so the reachable reef is
        // one viewport plus that travel — NOT the full pan range.
        let expected = viewport + (viewport * 3.5) * ParallaxMetrics.seabedRatio
        #expect(ParallaxMetrics.playableWidth(viewportWidth: viewport) == expected)
    }

    @Test func playableWidthIsNarrowerThanTheFullPanRange() {
        // Guards the exact bug: treating the reef as pan-range-wide strands
        // corals beyond the seabed's reach.
        let playable = ParallaxMetrics.playableWidth(viewportWidth: viewport)
        #expect(playable < ParallaxMetrics.panRange(viewportWidth: viewport))
    }

    @Test func aCoralAtThePlayableEdgeIsStillOnScreenAtFullScroll() {
        // Pan all the way left, then the right-most reachable coral should land
        // exactly at the right edge of the viewport.
        let panRange = ParallaxMetrics.panRange(viewportWidth: viewport)
        let edgeCoral = ParallaxMetrics.playableWidth(viewportWidth: viewport)
        let screenX = edgeCoral + ParallaxMetrics.seabedOffset(scrollX: -panRange)
        #expect(abs(screenX - viewport) < 0.001)
    }

    // MARK: - Ratio Agreement

    @Test func seabedRatioMatchesTheForegroundLayerRatio() {
        // If someone retunes the Foreground layer, this is the tripwire.
        #expect(ParallaxMetrics.seabedRatio == 0.20)
    }

    // MARK: - Resting Height

    // MARK: - Which Sand Is Under This Coral

    @Test func aCoralInTheFirstColumnReadsThatColumnsVariant() {
        // Corals and sand share a coordinate space — both translate by
        // `seabedOffset` — so a coral's xPos indexes straight into the sand
        // strip with no parallax term.
        let c = ParallaxMetrics.seabedColumn(layerX: 100, blockWidth: 600)
        #expect(c.variant == ParallaxMetrics.permutation(col: 0)[ParallaxMetrics.seabedVariantSlot])
        #expect(abs(c.localFraction - 100.0/600.0) < 0.0001)
    }

    @Test func aCoralPastTheFirstBlockReadsTheNextColumn() {
        let c = ParallaxMetrics.seabedColumn(layerX: 650, blockWidth: 600)
        #expect(c.variant == ParallaxMetrics.permutation(col: 1)[ParallaxMetrics.seabedVariantSlot])
        #expect(abs(c.localFraction - 50.0/600.0) < 0.0001)
    }

    @Test func aCoralExactlyOnABoundaryBelongsToTheNewColumn() {
        let c = ParallaxMetrics.seabedColumn(layerX: 600, blockWidth: 600)
        #expect(c.variant == ParallaxMetrics.permutation(col: 1)[ParallaxMetrics.seabedVariantSlot])
        #expect(abs(c.localFraction) < 0.0001)
    }

    @Test func aCoralLeftOfTheOriginStillResolves() {
        // Overscroll can push a coral's layer x negative; it must not crash or
        // wrap to a nonsense column.
        let c = ParallaxMetrics.seabedColumn(layerX: -50, blockWidth: 600)
        #expect(c.localFraction >= 0 && c.localFraction < 1)
    }

    @Test func everyPermutationCoversAllThreeVariants() {
        for col in -5...20 {
            #expect(ParallaxMetrics.permutation(col: col).sorted() == [0, 1, 2])
        }
    }

    // MARK: - Resting On The Curve

    @Test func aFragFromOpenWaterBedsIntoTheSandSurface() {
        // Lands on the sand at that x, then sinks in slightly so it reads as
        // planted rather than balanced on the line.
        let rest = ParallaxMetrics.restingHeight(dropHeight: 700, surfaceHeight: 167, embedDepth: 10)
        #expect(rest == 157)
    }

    @Test func theSurfaceVariesWithX() {
        // The whole point: two corals at different x land at different heights.
        let low = ParallaxMetrics.restingHeight(dropHeight: 700, surfaceHeight: 140, embedDepth: 10)
        let high = ParallaxMetrics.restingHeight(dropHeight: 700, surfaceHeight: 172, embedDepth: 10)
        #expect(high > low)
    }

    @Test func aFragPlacedInsideTheSandKeepsItsOwnDepth() {
        // Already below the bedded surface — respect where it was put.
        #expect(ParallaxMetrics.restingHeight(dropHeight: 90, surfaceHeight: 167, embedDepth: 10) == 90)
    }

    @Test func aFragReleasedBelowTheFloorClampsToIt() {
        #expect(ParallaxMetrics.restingHeight(dropHeight: -50, surfaceHeight: 167, embedDepth: 10) == 0)
    }

    @Test func aDegenerateSurfaceCollapsesToTheFloor() {
        // Guards the first layout pass, before the artwork has been measured.
        #expect(ParallaxMetrics.restingHeight(dropHeight: 300, surfaceHeight: 0, embedDepth: 10) == 0)
    }

    @Test func embedNeverPushesAFragThroughTheFloor() {
        #expect(ParallaxMetrics.restingHeight(dropHeight: 300, surfaceHeight: 4, embedDepth: 10) == 0)
    }

    // MARK: - Surface From A Sampled Profile

    @Test func surfaceHeightComesFromTheArtworksOwnSilhouette() {
        // topFraction 0.25 => sand starts a quarter down the image, so 75% of
        // the rendered height is sand.
        let h = ParallaxMetrics.surfaceHeight(topFraction: 0.25, renderedHeight: 200)
        #expect(abs(h - 150) < 0.0001)
    }

    @Test func aFullyOpaqueColumnIsSandAllTheWayUp() {
        #expect(ParallaxMetrics.surfaceHeight(topFraction: 0, renderedHeight: 200) == 200)
    }
}
