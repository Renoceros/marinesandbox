import Foundation

/// **EcoEngine: The Stateless Math Simulator**
///
/// Processes time-step calculations of the coral reef ecosystem's health as a **pure
/// function over value snapshots** (DEC-020): `ReefState` and `ThreatVector` in,
/// updated `ReefState` out. No SwiftData, no side effects — the view model maps the
/// persisted `@Model` graph to and from snapshots at the boundary. This is what lets
/// Fast Forward *compute* a steady state before showing the timelapse, and what lets
/// the sidecar SPM package unit-test the maths without a `ModelContainer` (DEC-022).
///
/// ### Core Pedagogical Concept:
/// Rather than acting as a scientific simulation, the math illustrates key ecological
/// principles implicitly (subliminally) through gameplay mechanics:
/// 1. **Biodiversity promotes resilience:** Higher Shannon Index ($H$) boosts herbivorous
///    fish recruitment, which automates algae removal. In a monoculture ($H = 0$), no
///    automated help is recruited, forcing players to manually clean algae.
/// 2. **Fragility of Bleached Corals:** Weakened bleached corals die if smothered by
///    algae ($>80\%$), demonstrating that global temperature stresses require local
///    ecosystem health to survive.
///
/// ### Exhibition dormancy (DEC-025):
/// Section D (heat stress / bleaching) is ported verbatim but **dormant in the
/// exhibition build**: no exhibition caller ever passes `waterTemperature > 30` or
/// `isHeatwaveActive: true` (`NGOConfig.heatwaveAllowed == false` enforces this).
/// It ships for the post-exhibition prestige-restart loop and is intentionally
/// untested until then.
///
public enum EcoEngine {

    // MARK: - Environmental Constants

    /// Modulates how strongly the Shannon Index ($H$) impacts fish recruitment.
    /// Higher values increase the efficiency multiplier of recruited helper fish.
    public static let beta: Double = 0.5

    /// Baseline growth progress added to healthy coral fragments per month.
    /// (Takes approximately 12 months for a healthy coral to reach maturity).
    public static let baseGrowthRate: Double = 0.08

    /// Baseline rate at which algae grows and spreads on corals.
    public static let baseAlgaeGrowthRate: Double = 0.06

    /// Baseline algae grazing capacity per recruited herbivore unit per month.
    public static let baseGrazingRate: Double = 0.03

    /// Baseline rate of tissue consumption per active pest (e.g. Drupella snail).
    /// Retuned 0.05 → 0.02 (DEC-030): at the 5 s/month demo pace (DEC-027), 0.05
    /// killed a two-snail coral in ~50 s of neglect — faster than a first-time
    /// player can learn the Hand tool. At 0.02 the 75% damage warning leaves ~1 min
    /// to react, and recruited wrasses (control 0.04) fully neutralize one snail.
    public static let basePredatorDamageRate: Double = 0.02

    /// Efficiency of recruited predatory fish (e.g. wrasses) in controlling pests.
    public static let basePredatorControlRate: Double = 0.04

    // MARK: - Simulation Loop

    /// Advances the reef forward by a number of simulation months.
    ///
    /// - Parameters:
    ///   - state: The current reef snapshot.
    ///   - threats: Active environmental parameters (runoff shocks, temperatures).
    ///   - months: Number of months to calculate (1 for active play ticks, 60 for
    ///     timelapse sweeps).
    /// - Returns: A new `ReefState` with the updates applied. The input is untouched.
    ///
    public static func step(state: ReefState, threats: ThreatVector, months: Int) -> ReefState {
        var state = state
        for _ in 0..<months {

            // 1. Calculate Shannon Diversity Index (H)
            // Measures species layout variety to determine helper fish recruitment efficiency
            let H = shannonIndex(of: state)

            // 2. Count Active Coral Growth Stages to Recruit Visual Fauna
            // Growing corals attract specific fish populations to the midground
            var herbivoreCount = 0
            var predatorCount = 0

            for coral in state.livingCorals where coral.isAdult {
                // Adult corals recruit grazing surgeonfish and pest-eating wrasses
                herbivoreCount += 1
                predatorCount += 1
            }

            // Recruited grazing & pest control rates, scaled by biodiversity index H
            let herbivoreRecruitment = Double(herbivoreCount) * (1.0 + beta * H)
            let predatorRecruitment = Double(predatorCount) * (1.0 + beta * H)

            // 3. Process Individual Biological Coral Fragments
            for index in state.corals.indices {
                guard !state.corals[index].isDead else { continue }

                // --- A. GROWTH CONSTRAINTS ---
                // Growth is slowed down proportionally by active algae coverage and predator damage
                let algaeSmotherModifier = max(0.0, 1.0 - state.corals[index].algaePercentage)
                let predatorModifier = max(0.0, 1.0 - state.corals[index].predatorDamage)

                let growthIncrement = baseGrowthRate * algaeSmotherModifier * predatorModifier
                state.corals[index].growthProgress = min(1.0, state.corals[index].growthProgress + growthIncrement)

                // --- B. ALGAE VS. GRAZER DYNAMICS ---
                // Agricultural runoff multiplies algae growth rate.
                // Baby & Teenager stages are highly vulnerable and grow algae faster.
                // Applied through the spatial grid (DEC-018): grow/graze keep the
                // aggregate rate identical to the old scalar maths while tracking
                // *where* the dirt is.
                let nutrientInflow = threats.agriculturalRunoff ? 2.5 : 1.0
                let vulnerable = state.corals[index].isBaby || state.corals[index].isTeenager
                let baseAlgaeRate = vulnerable ? baseAlgaeGrowthRate * 1.5 : baseAlgaeGrowthRate
                state.corals[index].coverage.grow(by: baseAlgaeRate * nutrientInflow)
                state.corals[index].coverage.graze(by: herbivoreRecruitment * baseGrazingRate)

                // --- C. PEST PREDATION DYNAMICS ---
                // activePredators counts active snails on this fragment.
                // Predatory fish (wrasses) mitigate pest damage.
                if !state.corals[index].activePredators.isEmpty {
                    let basePredation = basePredatorDamageRate * Double(state.corals[index].activePredators.count)
                    let predatorControl = predatorRecruitment * basePredatorControlRate
                    let netPredatorDamage = max(0.0, basePredation - predatorControl)

                    state.corals[index].predatorDamage = min(1.0, state.corals[index].predatorDamage + netPredatorDamage)
                }

                // --- D. WATER TEMPERATURE HEAT STRESS (dormant in exhibition — DEC-025) ---
                // Water temperatures above 30C trigger bleaching (zooxanthellae ejection).
                if threats.waterTemperature > 30.0 {
                    state.corals[index].isBleached = true
                } else if state.corals[index].isBleached && !threats.isHeatwaveActive && state.corals[index].algaePercentage < 0.3 {
                    // Bleached corals recover only if heatwaves end and algae levels are low (<30%)
                    state.corals[index].isBleached = false
                }

                // --- E. MORTALITY TRIGGERS ---
                // 1. Smothering: Bleached weakened corals die if smothered by algae (>80%)
                if state.corals[index].isBleached && state.corals[index].algaePercentage > 0.8 {
                    state.corals[index].isDead = true
                }
                // 2. Tissue Loss: Corals die if predator damage reaches 100%
                if state.corals[index].predatorDamage >= 1.0 {
                    state.corals[index].isDead = true
                }
            }
        }

        return state
    }

    // MARK: - Mathematical Helpers

    /// Computes the Shannon Entropy Index for the reef:
    /// $$H = -\sum (p_i \ln p_i)$$
    /// where $p_i$ is the relative proportion of living coral fragments belonging to species $i$.
    ///
    public static func shannonIndex(of state: ReefState) -> Double {
        let activeCorals = state.livingCorals
        guard !activeCorals.isEmpty else { return 0.0 }

        // Group active fragments by species
        let speciesCounts = Dictionary(grouping: activeCorals, by: { $0.species })
            .mapValues { $0.count }

        let total = Double(activeCorals.count)
        var shannonH: Double = 0.0

        for count in speciesCounts.values {
            let p_i = Double(count) / total
            if p_i > 0.0 {
                shannonH -= p_i * log(p_i)
            }
        }

        return shannonH
    }
}
