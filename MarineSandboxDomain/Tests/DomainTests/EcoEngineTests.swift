import Testing
import Foundation
@testable import Domain

/// Pins the behaviour of `EcoEngine` so the DEC-020 refactor and all future
/// tuning are verifiable. Every expectation is derived from the documented
/// constants: growth 0.08, algae 0.06 (×1.5 baby/teenager, ×2.5 runoff),
/// graze 0.03, pest damage 0.05, pest control 0.04, beta 0.5.
///
/// Section D (heat stress / bleaching triggers) is intentionally untested —
/// it ships dormant in the exhibition build per DEC-025.
@Suite("EcoEngine")
struct EcoEngineTests {

    // MARK: - Fixtures

    /// Benign exhibition threats: baseline 27°C, no runoff, no heatwave (DEC-025).
    let benign = ThreatVector()

    func coral(
        species: String = "Acropora",
        growth: Double = 0.0,
        algae: Double = 0.0,
        predatorDamage: Double = 0.0,
        predators: [String] = [],
        isBleached: Bool = false,
        isDead: Bool = false
    ) -> CoralState {
        CoralState(
            species: species,
            growthProgress: growth,
            coverage: AlgaeCoverage(uniform: algae),
            predatorDamage: predatorDamage,
            activePredators: predators,
            isBleached: isBleached,
            isDead: isDead
        )
    }

    func reef(_ corals: [CoralState]) -> ReefState {
        ReefState(ngoRegion: "Bali", corals: corals)
    }

    // MARK: - Shannon Diversity Index

    @Test func shannonIndexEmptyReefIsZero() {
        #expect(EcoEngine.shannonIndex(of: reef([])) == 0.0)
    }

    @Test func shannonIndexMonocultureIsZero() {
        let state = reef((0..<4).map { _ in coral(species: "Acropora") })
        #expect(EcoEngine.shannonIndex(of: state) == 0.0)
    }

    @Test func shannonIndexTwoBalancedSpeciesIsLn2() {
        let state = reef([
            coral(species: "Acropora"), coral(species: "Acropora"),
            coral(species: "BrainCoral"), coral(species: "BrainCoral"),
        ])
        #expect(abs(EcoEngine.shannonIndex(of: state) - log(2.0)) < 1e-10)
    }

    @Test func shannonIndexIgnoresDeadCorals() {
        let state = reef([
            coral(species: "Acropora"),
            coral(species: "BrainCoral", isDead: true),
        ])
        #expect(EcoEngine.shannonIndex(of: state) == 0.0)
    }

    // MARK: - Growth

    @Test func cleanCoralGrowsAtBaseRateForFirstMonth() {
        // Growth is computed from *current* algae (0) before this month's algae accrues.
        let result = EcoEngine.step(state: reef([coral(growth: 0.8)]), threats: benign, months: 1)
        #expect(abs(result.corals[0].growthProgress - 0.88) < 1e-10)
    }

    @Test func fullySmotheredCoralDoesNotGrow() {
        let result = EcoEngine.step(state: reef([coral(growth: 0.5, algae: 1.0)]), threats: benign, months: 1)
        #expect(result.corals[0].growthProgress == 0.5)
    }

    @Test func growthClampsAtMaturity() {
        let result = EcoEngine.step(state: reef([coral(growth: 0.99)]), threats: benign, months: 1)
        #expect(result.corals[0].growthProgress == 1.0)
    }

    // MARK: - Algae vs. Grazer Dynamics

    @Test func babyCoralWithRunoffGrowsAlgaeAtCombinedRate() {
        // 0.06 base × 1.5 vulnerability × 2.5 runoff = 0.225/month gross.
        let threats = ThreatVector(agriculturalRunoff: true)
        let result = EcoEngine.step(state: reef([coral()]), threats: threats, months: 1)
        #expect(abs(result.corals[0].algaePercentage - 0.225) < 1e-4)
    }

    @Test func adultCoralInMonocultureGrazesAtBaseRate() {
        // One adult, H = 0 → recruitment 1 × (1 + 0.5 × 0) = 1 → graze 0.03.
        // Net for the month: grow 0.06 − graze 0.03 = +0.03 on top of the 0.1 fixture.
        let result = EcoEngine.step(state: reef([coral(growth: 1.0, algae: 0.1)]), threats: benign, months: 1)
        #expect(abs(result.corals[0].algaePercentage - 0.13) < 1e-4)
    }

    @Test func biodiversityBoostsRecruitment() {
        // Two adults of different species: H = ln 2 → recruitment 1.346 per unit,
        // outgrowing the 0.06 baseline → algae falls despite no brushing.
        let state = reef([
            coral(species: "Acropora", growth: 1.0, algae: 0.5),
            coral(species: "BrainCoral", growth: 1.0, algae: 0.5),
        ])
        let result = EcoEngine.step(state: state, threats: benign, months: 1)
        #expect(result.corals[0].algaePercentage < 0.5)
        #expect(result.corals[1].algaePercentage < 0.5)
    }

    // MARK: - Pests & Mortality

    @Test func snailInflictsBaseDamageWithoutWrasses() {
        // DEC-030: base pest damage is 0.02/month — slow enough to react to.
        let result = EcoEngine.step(state: reef([coral(predators: ["DrupellaSnail"])]), threats: benign, months: 1)
        #expect(abs(result.corals[0].predatorDamage - 0.02) < 1e-10)
    }

    @Test func adultWrassesNeutralizeOneSnail() {
        // One adult: predator control 0.04 vs snail damage 0.02 → net 0 (floored).
        // The manual→automated arc made literal (PRD §3.2).
        let result = EcoEngine.step(
            state: reef([coral(growth: 1.0, predators: ["DrupellaSnail"])]),
            threats: benign,
            months: 1
        )
        #expect(result.corals[0].predatorDamage == 0.0)
    }

    @Test func fullTissueLossKillsCoral() {
        let result = EcoEngine.step(
            state: reef([coral(predatorDamage: 0.99, predators: ["DrupellaSnail"])]),
            threats: benign,
            months: 1
        )
        #expect(result.corals[0].isDead)
    }

    @Test func bleachedCoralSmotheredByAlgaeDies() {
        // Bleached state constructed directly — §D's temperature trigger is
        // dormant in the exhibition build (DEC-025) and must not be used here.
        let result = EcoEngine.step(
            state: reef([coral(growth: 1.0, algae: 0.85, isBleached: true)]),
            threats: benign,
            months: 1
        )
        #expect(result.corals[0].isDead)
    }

    @Test func deadCoralsStayDead() {
        let result = EcoEngine.step(state: reef([coral(isDead: true)]), threats: benign, months: 1)
        #expect(result.corals[0].isDead)
        #expect(result.corals[0].growthProgress == 0.0)
    }

    // MARK: - Purity & Timelapse

    @Test func stepDoesNotMutateInput() {
        let input = reef([coral(growth: 0.5, algae: 0.2, predators: ["DrupellaSnail"])])
        let copy = input
        _ = EcoEngine.step(state: input, threats: benign, months: 3)
        #expect(input == copy)
    }

    @Test func timelapseSweepIsDeterministicAndBounded() {
        let state = reef([
            coral(species: "Acropora", growth: 0.4, algae: 0.3, predators: ["DrupellaSnail"]),
            coral(species: "Acropora", growth: 0.1),
            coral(species: "BrainCoral", growth: 0.8, algae: 0.2),
        ])
        let first = EcoEngine.step(state: state, threats: benign, months: 60)
        let second = EcoEngine.step(state: state, threats: benign, months: 60)

        #expect(first == second)
        for coral in first.corals {
            #expect((0.0...1.0).contains(coral.growthProgress))
            #expect((0.0...1.0).contains(coral.algaePercentage))
            #expect((0.0...1.0).contains(coral.predatorDamage))
            #expect(!coral.growthProgress.isNaN)
            #expect(!coral.algaePercentage.isNaN)
            #expect(!coral.predatorDamage.isNaN)
        }
    }
}
