import Testing
import Foundation
@testable import Domain

/// Pins the behaviour of the time-based `EcoEngine` (DEC-031) so all future tuning
/// is verifiable. Rates are per real-second: healthy maturation 1/`maturationInterval`
/// (7 days), algae 1/(3 days), pest damage 1/(3 days), pest control 2×, beta 0.5.
///
/// Section D (heat stress / bleaching triggers) is intentionally untested —
/// it ships dormant in the exhibition build per DEC-025.
@Suite("EcoEngine")
struct EcoEngineTests {

    // MARK: - Fixtures

    /// Benign exhibition threats: baseline 27°C, no runoff, no heatwave (DEC-025).
    let benign = ThreatVector()

    /// One day in seconds — a convenient, lifecycle-relevant advance span.
    let oneDay: TimeInterval = 24 * 60 * 60

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

    /// Healthy growth accrued over one day = `86400 / maturationInterval`.
    var healthyGrowthPerDay: Double { oneDay / EcoEngine.maturationInterval }

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

    // MARK: - Growth (time-based, DEC-031)

    @Test func cleanCoralGrowsByHealthyRateOverOneDay() {
        // Growth uses *current* algae (0) before this step's algae accrues.
        let result = EcoEngine.advance(state: reef([coral(growth: 0.8)]), threats: benign, elapsed: oneDay)
        #expect(abs(result.corals[0].growthProgress - (0.8 + healthyGrowthPerDay)) < 1e-9)
    }

    @Test func fullySmotheredCoralDoesNotGrow() {
        let result = EcoEngine.advance(state: reef([coral(growth: 0.5, algae: 1.0)]), threats: benign, elapsed: oneDay)
        #expect(result.corals[0].growthProgress == 0.5)
    }

    @Test func neglectSlowsButDoesNotPauseGrowth() {
        // 50% algae → modifier 0.5 → half the healthy rate (DEC-031: prolong, don't pause).
        let result = EcoEngine.advance(state: reef([coral(growth: 0.5, algae: 0.5)]), threats: benign, elapsed: oneDay)
        #expect(abs(result.corals[0].growthProgress - (0.5 + healthyGrowthPerDay * 0.5)) < 1e-9)
    }

    @Test func growthClampsAtMaturity() {
        let result = EcoEngine.advance(state: reef([coral(growth: 0.99)]), threats: benign, elapsed: oneDay)
        #expect(result.corals[0].growthProgress == 1.0)
    }

    @Test func perCoralClocksAreIndependent() {
        // Same elapsed, different modifiers → different growth. Each coral's clock
        // runs on its own algae/pest state (DEC-031 per-coral lifecycle).
        let result = EcoEngine.advance(
            state: reef([
                coral(growth: 0.4, algae: 0.0),
                coral(growth: 0.4, algae: 1.0),
            ]),
            threats: benign,
            elapsed: oneDay
        )
        #expect(result.corals[0].growthProgress > 0.4)
        #expect(result.corals[1].growthProgress == 0.4)
    }

    // MARK: - Algae vs. Grazer Dynamics

    @Test func babyCoralWithRunoffAccruesAlgae() {
        // Baby (vulnerable ×1.5) + runoff (×2.5) over one hour. Directional: algae
        // rises, stays below saturation for a short span.
        let threats = ThreatVector(agriculturalRunoff: true)
        let oneHour: TimeInterval = 60 * 60
        let result = EcoEngine.advance(state: reef([coral()]), threats: threats, elapsed: oneHour)
        #expect(result.corals[0].algaePercentage > 0.0)
        #expect(result.corals[0].algaePercentage < 1.0)
    }

    @Test func biodiversityBoostsRecruitment() {
        // Two adults of different species: H = ln 2 → recruitment > 1, outgrazing
        // the baseline → algae falls despite no brushing.
        let state = reef([
            coral(species: "Acropora", growth: 1.0, algae: 0.5),
            coral(species: "BrainCoral", growth: 1.0, algae: 0.5),
        ])
        let result = EcoEngine.advance(state: state, threats: benign, elapsed: oneDay)
        #expect(result.corals[0].algaePercentage < 0.5)
        #expect(result.corals[1].algaePercentage < 0.5)
    }

    // MARK: - Pests & Mortality

    @Test func snailInflictsBaseDamageWithoutWrasses() {
        // One snail, no adults: damage = basePredatorDamageRatePerSecond × elapsed.
        let result = EcoEngine.advance(state: reef([coral(predators: ["DrupellaSnail"])]), threats: benign, elapsed: oneDay)
        let expected = EcoEngine.basePredatorDamageRatePerSecond * oneDay
        #expect(abs(result.corals[0].predatorDamage - expected) < 1e-9)
    }

    @Test func adultWrassesNeutralizeOneSnail() {
        // One adult: control (2× damage rate) > one snail's damage → net 0.
        // The manual→automated arc made literal (PRD §3.2).
        let result = EcoEngine.advance(
            state: reef([coral(growth: 1.0, predators: ["DrupellaSnail"])]),
            threats: benign,
            elapsed: oneDay
        )
        #expect(result.corals[0].predatorDamage == 0.0)
    }

    @Test func fullTissueLossKillsCoral() {
        let result = EcoEngine.advance(
            state: reef([coral(predatorDamage: 0.99, predators: ["DrupellaSnail"])]),
            threats: benign,
            elapsed: oneDay
        )
        #expect(result.corals[0].isDead)
    }

    @Test func bleachedCoralSmotheredByAlgaeDies() {
        // Bleached state constructed directly — §D's temperature trigger is
        // dormant in the exhibition build (DEC-025) and must not be used here.
        let result = EcoEngine.advance(
            state: reef([coral(growth: 1.0, algae: 0.85, isBleached: true)]),
            threats: benign,
            elapsed: oneDay
        )
        #expect(result.corals[0].isDead)
    }

    @Test func deadCoralsStayDead() {
        let result = EcoEngine.advance(state: reef([coral(isDead: true)]), threats: benign, elapsed: oneDay)
        #expect(result.corals[0].isDead)
        #expect(result.corals[0].growthProgress == 0.0)
    }

    // MARK: - Graceful Catch-Up (DEC-031)

    @Test func catchUpNeverKillsEvenWhenMortalityWouldFire() {
        // Pests would push damage over 1.0 and bleaching+algae would smother — but
        // catch-up passes allowDeath: false, so the player never returns to a dead reef.
        // Neither coral is an adult, so no wrasses are recruited to neutralize the snail.
        let state = reef([
            coral(predatorDamage: 0.99, predators: ["DrupellaSnail"]),
            coral(growth: 0.0, algae: 0.85, isBleached: true),
        ])
        let result = EcoEngine.advance(state: state, threats: benign, elapsed: oneDay, allowDeath: false)
        #expect(!result.corals[0].isDead)
        #expect(!result.corals[1].isDead)
        #expect(result.corals[0].predatorDamage > 0.99) // damage still accrues
    }

    @Test func catchUpGrowsCorals() {
        let result = EcoEngine.advance(state: reef([coral(growth: 0.2)]), threats: benign, elapsed: oneDay, allowDeath: false)
        #expect(result.corals[0].growthProgress > 0.2)
    }

    @Test func allowDeathTrueLetsMortalityFire() {
        // Same smothered-bleached coral, but live play (allowDeath: true) → dies.
        let state = reef([coral(growth: 1.0, algae: 0.85, isBleached: true)])
        let live = EcoEngine.advance(state: state, threats: benign, elapsed: oneDay, allowDeath: true)
        let caughtUp = EcoEngine.advance(state: state, threats: benign, elapsed: oneDay, allowDeath: false)
        #expect(live.corals[0].isDead)
        #expect(!caughtUp.corals[0].isDead)
    }

    @Test func zeroElapsedReturnsInputUnchanged() {
        let state = reef([coral(growth: 0.5)])
        let result = EcoEngine.advance(state: state, threats: benign, elapsed: 0)
        #expect(result == state)
    }

    // MARK: - Purity & Timelapse

    @Test func advanceDoesNotMutateInput() {
        let input = reef([coral(growth: 0.5, algae: 0.2, predators: ["DrupellaSnail"])])
        let copy = input
        _ = EcoEngine.advance(state: input, threats: benign, elapsed: 3 * oneDay)
        #expect(input == copy)
    }

    @Test func timelapseSweepIsDeterministicAndBounded() {
        let state = reef([
            coral(species: "Acropora", growth: 0.4, algae: 0.3, predators: ["DrupellaSnail"]),
            coral(species: "Acropora", growth: 0.1),
            coral(species: "BrainCoral", growth: 0.8, algae: 0.2),
        ])
        let first = EcoEngine.advance(state: state, threats: benign, elapsed: 30 * oneDay)
        let second = EcoEngine.advance(state: state, threats: benign, elapsed: 30 * oneDay)

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
