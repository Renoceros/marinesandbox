import Testing
import Foundation
@testable import Domain

/// Pins model-space hit-testing (DEC-019): interactions must resolve against
/// geometry derived from the model, never from whatever art is on screen.
@Suite("CoralGeometry")
struct CoralGeometryTests {

    let seabedY = 700.0

    func coral(growth: Double, x: Double = 500, y: Double = 0) -> CoralState {
        CoralState(species: "Acropora", xPos: x, yPos: y, growthProgress: growth)
    }

    @Test func footprintFollowsGrowthStage() {
        // Living babies render as the colored shiny frag (DEC-009: alive must look alive).
        #expect(CoralGeometry.footprint(for: coral(growth: 0.1)).assetName == "ShinyFragment")
        #expect(CoralGeometry.footprint(for: coral(growth: 0.4)).assetName == "CoralToddler")
        #expect(CoralGeometry.footprint(for: coral(growth: 0.6)).assetName == "CoralTeen")
        #expect(CoralGeometry.footprint(for: coral(growth: 0.9)).assetName == "CoralAdult")
    }

    @Test func deadBabyRendersAsGrayRubble() {
        var dead = coral(growth: 0.1)
        dead.isDead = true
        #expect(CoralGeometry.footprint(for: dead).assetName == "Fragment1")
    }

    @Test func hitRectIsBottomCenterAnchored() {
        let rect = CoralGeometry.hitRect(for: coral(growth: 0.9, x: 500), seabedY: seabedY)
        #expect(abs(rect.midX - 500) < 1e-10)
        #expect(abs(rect.maxY - seabedY) < 1e-10)
        #expect(abs(rect.width - 193.21) < 1e-2)
    }

    @Test func hitRectLiftsSpriteAboveSeabedByYPos() {
        let perched = coral(growth: 0.9, y: 100) // fan coral on a boulder, 100pt up
        let rect = CoralGeometry.hitRect(for: perched, seabedY: seabedY)
        #expect(abs(rect.maxY - (seabedY - 100)) < 1e-10)
    }

    @Test func hitTestFindsTappedCoral() {
        let corals = [coral(growth: 0.9)]
        // Center of the adult sprite whose base sits on the seabed.
        #expect(CoralGeometry.hitTest(corals: corals, at: CGPoint(x: 500, y: seabedY - 121), seabedY: seabedY)?.id == corals[0].id)
        // Far outside the sprite.
        #expect(CoralGeometry.hitTest(corals: corals, at: CGPoint(x: 50, y: 50), seabedY: seabedY) == nil)
    }

    @Test func hitTestIgnoresDeadCorals() {
        var dead = coral(growth: 0.9)
        dead.isDead = true
        #expect(CoralGeometry.hitTest(corals: [dead], at: CGPoint(x: 500, y: seabedY - 121), seabedY: seabedY) == nil)
    }

    @Test func localPointNormalisesIntoGridSpace() {
        let c = coral(growth: 0.9, x: 500)
        let center = CoralGeometry.localPoint(in: c, canvasPoint: CGPoint(x: 500, y: seabedY - 243.32 / 2), seabedY: seabedY)
        #expect(center != nil)
        #expect(abs(center!.x - 0.5) < 1e-3)
        #expect(abs(center!.y - 0.5) < 1e-3)
        // A miss returns nil rather than clamping — brushing past a coral is a no-op.
        #expect(CoralGeometry.localPoint(in: c, canvasPoint: CGPoint(x: 0, y: 0), seabedY: seabedY) == nil)
    }
}
