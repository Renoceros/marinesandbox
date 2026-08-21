import Testing
import Foundation
@testable import Domain

/// Pins the tactile layer (TASK-MVP-104, DEC-012): the flick threshold and the
/// ballistic throw are player-visible feel, so they are pinned by tests.
@Suite("Physics")
struct PhysicsTests {

    // MARK: - Flick Threshold

    @Test func releaseBelowThresholdIsNotAFlick() {
        #expect(!Physics.isFlick(velocity: CGPoint(x: 99, y: 0)))
        #expect(!Physics.isFlick(velocity: CGPoint(x: 70, y: 70))) // ~99 pt/s diagonal
    }

    @Test func releaseAboveThresholdIsAFlick() {
        #expect(Physics.isFlick(velocity: CGPoint(x: 101, y: 0)))
        #expect(Physics.isFlick(velocity: CGPoint(x: 0, y: -500)))
    }

    // MARK: - Ballistic Throw

    @Test func throwPositionIsDeterministic() {
        let origin = CGPoint(x: 100, y: 300)
        let velocity = CGPoint(x: 400, y: -600)
        let a = Physics.throwPosition(from: origin, velocity: velocity, at: 0.25)
        let b = Physics.throwPosition(from: origin, velocity: velocity, at: 0.25)
        #expect(a == b)
        // x = 100 + 400 × 0.25 = 200; y = 300 − 600 × 0.25 + 0.5 × 2000 × 0.0625 = 212.5
        #expect(abs(a.x - 200.0) < 1e-10)
        #expect(abs(a.y - 212.5) < 1e-10)
    }

    @Test func thrownPestEventuallyLeavesViewport() {
        let viewport = CGRect(x: 0, y: 0, width: 393, height: 852)
        let despawn = Physics.despawnTime(
            from: CGPoint(x: 200, y: 400),
            velocity: CGPoint(x: 800, y: 0),
            viewport: viewport
        )
        #expect(despawn != nil)
        #expect(despawn! < 1.0)
    }

    @Test func releasedPestFallsOutOfViewportUnderGravity() {
        // Gravity acts even with zero initial velocity — a released pest drops
        // off the bottom of the screen rather than hovering forever.
        let viewport = CGRect(x: 0, y: 0, width: 393, height: 852)
        let despawn = Physics.despawnTime(
            from: CGPoint(x: 200, y: 400),
            velocity: .zero,
            viewport: viewport
        )
        #expect(despawn != nil)
        #expect(despawn! < 1.0)
    }

    // MARK: - Planting

    @Test func canvasPointCompensatesScrollOffset() {
        let point = Physics.canvasPoint(fromScreenPoint: CGPoint(x: 100, y: 500), scrollX: -400)
        #expect(point.x == 500)
        #expect(point.y == 500)
    }

    @Test func dropIsClampedToPlayableBounds() {
        // DEBT-001: the world is bounded; drops outside the canvas clamp inward.
        let left = Physics.clampedDrop(CGPoint(x: -500, y: 100), canvasWidth: 2000)
        #expect(left.x == 20)
        let right = Physics.clampedDrop(CGPoint(x: 9999, y: 100), canvasWidth: 2000)
        #expect(right.x == 1980)
        let inside = Physics.clampedDrop(CGPoint(x: 1000, y: -50), canvasWidth: 2000)
        #expect(inside.x == 1000)
        #expect(inside.y == 0)
    }

    // MARK: - Sink Settle (motion: fluid material, distance-scaled duration)

    @Test func sinkFromTheSeabedSettlesAtTheFloorResponse() {
        // Dropped with no height to fall, the settle should feel immediate.
        #expect(Physics.sinkResponse(fallHeight: 0, viewportHeight: 800) == Physics.sinkResponseFloor)
    }

    @Test func sinkResponseGrowsWithFallHeight() {
        let shallow = Physics.sinkResponse(fallHeight: 100, viewportHeight: 800)
        let deep = Physics.sinkResponse(fallHeight: 600, viewportHeight: 800)
        #expect(deep > shallow)
    }

    @Test func sinkFromTheSurfaceCapsAtTheSlowestResponse() {
        // A drop at the very top of the water is the longest sink there is.
        #expect(Physics.sinkResponse(fallHeight: 800, viewportHeight: 800) == Physics.sinkResponseCap)
    }

    @Test func sinkResponseClampsNonsenseInput() {
        // Negative height (drop below the sand) and overscrolled height both
        // resolve to the ends of the range rather than a wild spring.
        #expect(Physics.sinkResponse(fallHeight: -200, viewportHeight: 800) == Physics.sinkResponseFloor)
        #expect(Physics.sinkResponse(fallHeight: 5000, viewportHeight: 800) == Physics.sinkResponseCap)
    }

    @Test func sinkResponseSurvivesADegenerateViewport() {
        // Guards a divide-by-zero before the first layout pass.
        #expect(Physics.sinkResponse(fallHeight: 100, viewportHeight: 0) == Physics.sinkResponseCap)
    }

    @Test func settleDurationOutlastsTheSpringResponse() {
        // The model write is committed once the frag has visually arrived, so
        // this must cover the spring's tail rather than cut it off.
        #expect(Physics.sinkSettleDuration(response: 1.0) > 1.0)
    }

    @Test func settleDurationScalesWithResponse() {
        let slow = Physics.sinkSettleDuration(response: 1.2)
        let quick = Physics.sinkSettleDuration(response: 0.55)
        #expect(slow > quick)
    }
}
