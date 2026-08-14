import Testing
import Foundation
@testable import Domain

/// Pins model-space hit-testing (DEC-019): interactions must resolve against
/// geometry derived from the model, never from whatever art is on screen.
@Suite("CoralGeometry")
struct CoralGeometryTests {

    func coral(growth: Double, x: Double = 500, y: Double = 700) -> CoralState {
        CoralState(species: "Acropora", xPos: x, yPos: y, growthProgress: growth)
    }

    @Test func footprintFollowsGrowthStage() {
        #expect(CoralGeometry.footprint(for: coral(growth: 0.1)).assetName == "Fragment1")
        #expect(CoralGeometry.footprint(for: coral(growth: 0.4)).assetName == "CoralToddler")
        #expect(CoralGeometry.footprint(for: coral(growth: 0.6)).assetName == "CoralTeen")
        #expect(CoralGeometry.footprint(for: coral(growth: 0.9)).assetName == "CoralAdult")
    }

    @Test func hitRectIsBottomCenterAnchored() {
        let rect = CoralGeometry.hitRect(for: coral(growth: 0.9, x: 500, y: 700))
        #expect(abs(rect.midX - 500) < 1e-10)
        #expect(abs(rect.maxY - 700) < 1e-10)
        #expect(abs(rect.width - 193.21) < 1e-2)
    }

    @Test func hitTestFindsTappedCoral() {
        let corals = [coral(growth: 0.9)]
        // Center of the adult sprite at (500, 700 − 243.32/2).
        #expect(CoralGeometry.hitTest(corals: corals, at: CGPoint(x: 500, y: 578))?.id == corals[0].id)
        // Far outside the sprite.
        #expect(CoralGeometry.hitTest(corals: corals, at: CGPoint(x: 50, y: 50)) == nil)
    }

    @Test func hitTestIgnoresDeadCorals() {
        var dead = coral(growth: 0.9)
        dead.isDead = true
        #expect(CoralGeometry.hitTest(corals: [dead], at: CGPoint(x: 500, y: 578)) == nil)
    }

    @Test func localPointNormalisesIntoGridSpace() {
        let c = coral(growth: 0.9, x: 500, y: 700)
        let center = CoralGeometry.localPoint(in: c, canvasPoint: CGPoint(x: 500, y: 700 - 243.32 / 2))
        #expect(center != nil)
        #expect(abs(center!.x - 0.5) < 1e-3)
        #expect(abs(center!.y - 0.5) < 1e-3)
        // A miss returns nil rather than clamping — brushing past a coral is a no-op.
        #expect(CoralGeometry.localPoint(in: c, canvasPoint: CGPoint(x: 0, y: 0)) == nil)
    }
}
