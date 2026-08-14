import Testing
import Foundation
@testable import Domain

/// Pins the spatial dirt model (DEC-018): the brush and helper-fish grazing both
/// mutate this grid, so its behaviour is player-visible in two different mechanics.
@Suite("AlgaeCoverage")
struct AlgaeCoverageTests {

    // MARK: - Aggregates

    @Test func uniformGridReportsUniformPercentage() {
        #expect(abs(AlgaeCoverage(uniform: 0.4).percentage - 0.4) < 1e-4)
    }

    @Test func growKeepsAggregateRateDespiteBaseBias() {
        // Row bias (base colonises first) averages to exactly 1.0 across the grid,
        // so a uniform grow moves the aggregate by the requested amount.
        var grid = AlgaeCoverage()
        grid.grow(by: 0.1)
        #expect(abs(grid.percentage - 0.1) < 1e-4)
    }

    @Test func growBiasesTowardTheBase() {
        var grid = AlgaeCoverage()
        grid.grow(by: 0.1)
        let topRow = (0..<6).map { grid.coverage(at: $0) }
        let bottomRow = (30..<36).map { grid.coverage(at: $0) }
        #expect(bottomRow.allSatisfy { $0 > topRow[0] })
    }

    @Test func coverageClampsAtFullSaturation() {
        var grid = AlgaeCoverage(uniform: 0.95)
        grid.grow(by: 0.5)
        #expect(grid.percentage <= 1.0)
        #expect(grid.coverage(at: 35) == 1.0)
    }

    // MARK: - Grazing

    @Test func grazeRemovesThickestPatchesFirst() {
        var grid = AlgaeCoverage()
        grid.grow(by: 0.1) // bottom rows thickest
        let before = grid.percentage
        grid.graze(by: 0.05)
        #expect(grid.percentage < before)
        // Bottom row should have lost more than the top row.
        let top = (0..<6).map { grid.coverage(at: $0) }
        let bottom = (30..<36).map { grid.coverage(at: $0) }
        #expect(zip(top, bottom).allSatisfy { $1 <= $0 })
    }

    @Test func grazeIsDeterministic() {
        var a = AlgaeCoverage(uniform: 0.6)
        var b = AlgaeCoverage(uniform: 0.6)
        a.graze(by: 0.2)
        b.graze(by: 0.2)
        #expect(a == b)
    }

    @Test func grazeCannotExceedAvailableAlgae() {
        var grid = AlgaeCoverage(uniform: 0.01)
        grid.graze(by: 1.0)
        #expect(grid.isClean)
    }

    // MARK: - Brushing

    @Test func brushStrokeClearsCellsAndReportsThem() {
        var grid = AlgaeCoverage(uniform: 0.8)
        let center = AlgaeCoverage.center(of: 14) // middle of the grid
        let cleared = grid.clear(
            from: CGPoint(x: center.x, y: center.y),
            to: CGPoint(x: center.x, y: center.y)
        )
        #expect(cleared.contains(14))
        #expect(grid.coverage(at: 14) == 0)
    }

    @Test func fastSwipeLeavesNoUncleanedStripe() {
        // A horizontal swipe across the full width at mid-height must clear every
        // cell in the middle rows — interpolation between drag samples is what
        // prevents stripes (DEC-018).
        var grid = AlgaeCoverage(uniform: 1.0)
        grid.clear(from: CGPoint(x: 0, y: 0.5), to: CGPoint(x: 1, y: 0.5))
        let middleRows = [14, 15, 16, 20, 21] // rows 2-3, all columns crossed
        #expect(middleRows.allSatisfy { grid.coverage(at: $0) == 0 })
    }

    @Test func cleanGridReportsClean() {
        #expect(AlgaeCoverage().isClean)
        #expect(!AlgaeCoverage(uniform: 0.01).isClean)
    }

    // MARK: - Geometry

    @Test func cellCentersAreNormalised() {
        let first = AlgaeCoverage.center(of: 0)
        #expect(abs(first.x - 1.0 / 12.0) < 1e-10)
        #expect(abs(first.y - 1.0 / 12.0) < 1e-10)
        let last = AlgaeCoverage.center(of: 35)
        #expect(abs(last.x - 11.0 / 12.0) < 1e-10)
        #expect(abs(last.y - 11.0 / 12.0) < 1e-10)
    }

    @Test func outOfRangeCoverageIsZero() {
        #expect(AlgaeCoverage(uniform: 1.0).coverage(at: 36) == 0)
        #expect(AlgaeCoverage(uniform: 1.0).coverage(at: -1) == 0)
    }
}
