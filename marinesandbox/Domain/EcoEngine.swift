import Foundation

/// **EcoEngine: The Stateless Time-Based Simulator (DEC-031)**
///
/// Processes time-step calculations of the coral reef ecosystem's health as a **pure
/// function over value snapshots** (DEC-020): `ReefState` and `ThreatVector` in,
/// updated `ReefState` out. No SwiftData, no side effects — the view model maps the
/// persisted `@Model` graph to and from snapshots at the boundary. This is what lets
/// Fast Forward *compute* a steady state before showing the timelapse, and what lets
/// the sidecar SPM package unit-test the maths without a `ModelContainer` (DEC-022).
///
/// ### Real-time lifecycle (DEC-031, supersedes DEC-027):
/// Each coral has its own 7-day lifecycle anchored to `plantedAt`. 7 days is the
/// **healthy best case** — algae smothering and pest damage *slow* the per-coral growth
/// clock (prolong maturation, never pause it), so a neglected coral takes longer than
/// 7 days to mature and may die. Growth accrues by elapsed real time, including while
/// the app is closed: `SandboxViewModel` computes `now - lastSeenAt` and calls
/// `advance(..., allowDeath: false)` for graceful catch-up (growth + algae accrual,
/// no offline death). The live tick calls `advance` with the refresh slice and
/// `allowDeath: true`.
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

    // MARK: - Lifecycle & Rate Constants (per second; DEC-031)
    //
    // All rates are per real-second so the engine advances by elapsed wall time.
    // Values target a 7-day healthy maturation with algae/pest threatening over
    // ~1–3 days of neglect. Retune here after floor-testing — structure stays.

    /// Healthy best-case time for a coral to grow from `0.0` to `1.0` (7 days).
    public static let maturationInterval: TimeInterval = 7 * 24 * 60 * 60

    /// Healthy growth progress per second = `1 / maturationInterval`. Slowed by algae
    /// and pest modifiers per coral (DEC-031: prolong, don't pause).
    public static var healthyGrowthRatePerSecond: Double { 1.0 / maturationInterval }

    /// Baseline algae growth per second. Targets full smother (~1.0) on a clean
    /// non-vulnerable coral in ~3 days of total neglect with no grazers.
    public static let baseAlgaeGrowthRatePerSecond: Double = 1.0 / (3 * 24 * 60 * 60)

    /// Baseline algae grazing capacity per recruited herbivore unit per second.
    public static let baseGrazingRatePerSecond: Double = baseAlgaeGrowthRatePerSecond * 0.5

    /// Tissue consumed per second per active pest (e.g. Drupella snail).
    /// Targets a one-snail kill in ~3 days of uncontrolled neglect. DEC-030's structure
    /// (modifier-based slowdown, no tutorial death) is preserved; the value is retuned
    /// for real-time pacing and should be re-checked after floor-testing.
    public static let basePredatorDamageRatePerSecond: Double = 1.0 / (3 * 24 * 60 * 60)

    /// Efficiency of recruited predatory fish (e.g. wrasses) in controlling pests,
    /// per second. Twice the per-snail damage so one wrasse neutralizes ~2 snails.
    public static let basePredatorControlRatePerSecond: Double = basePredatorDamageRatePerSecond * 2.0

    /// Modulates how strongly the Shannon Index ($H$) impacts fish recruitment.
    /// Higher values increase the efficiency multiplier of recruited helper fish.
    public static let beta: Double = 0.5

    // MARK: - Simulation Loop

    /// Advances the reef forward by a span of real time (DEC-031).
    ///
    /// Growth, algae, and pest dynamics all advance by `elapsed` seconds. Each coral's
    /// growth is slowed by its own algae/pest modifiers, so the per-coral clock runs
    /// independently — a neglected coral takes longer than 7 days to mature. Mortality
    /// only fires when `allowDeath` is true: graceful catch-up passes `false` so a
    /// player never returns to a dead reef (the return moment is a reveal, not a
    /// punishment).
    ///
    /// - Parameters:
    ///   - state: The current reef snapshot.
    ///   - threats: Active environmental parameters (runoff shocks, temperatures).
    ///   - elapsed: Real seconds to advance by (the catch-up gap, the live tick slice,
    ///     or an exhibition Fast Forward jump).
    ///   - allowDeath: Whether mortality triggers may fire. `false` for offline catch-up.
    /// - Returns: A new `ReefState` with the updates applied. The input is untouched.
    ///
    public static func advance(
        state: ReefState,
        threats: ThreatVector,
        elapsed: TimeInterval,
        allowDeath: Bool = true
    ) -> ReefState {
        guard elapsed > 0 else { return state }
        var state = state

        let H = shannonIndex(of: state)

        // Count adult corals to recruit visual fauna (grazers + pest controllers).
        var herbivoreCount = 0
        var predatorCount = 0
        for coral in state.livingCorals where coral.isAdult {
            herbivoreCount += 1
            predatorCount += 1
        }

        let herbivoreRecruitment = Double(herbivoreCount) * (1.0 + beta * H)
        let predatorRecruitment = Double(predatorCount) * (1.0 + beta * H)

        for index in state.corals.indices {
            guard !state.corals[index].isDead else { continue }

            // --- A. GROWTH (slowed by algae + pest, DEC-031) ---
            let algaeSmotherModifier = max(0.0, 1.0 - state.corals[index].algaePercentage)
            let predatorModifier = max(0.0, 1.0 - state.corals[index].predatorDamage)
            let growthIncrement = healthyGrowthRatePerSecond * elapsed * algaeSmotherModifier * predatorModifier
            state.corals[index].growthProgress = min(1.0, state.corals[index].growthProgress + growthIncrement)

            // --- B. ALGAE VS. GRAZER DYNAMICS (spatial grid, DEC-018) ---
            let nutrientInflow = threats.agriculturalRunoff ? 2.5 : 1.0
            let vulnerable = state.corals[index].isBaby || state.corals[index].isTeenager
            let baseAlgaeRate = (vulnerable ? baseAlgaeGrowthRatePerSecond * 1.5 : baseAlgaeGrowthRatePerSecond) * nutrientInflow
            state.corals[index].coverage.grow(by: baseAlgaeRate * elapsed)
            state.corals[index].coverage.graze(by: herbivoreRecruitment * baseGrazingRatePerSecond * elapsed)

            // --- C. PEST PREDATION DYNAMICS ---
            if !state.corals[index].activePredators.isEmpty {
                let basePredation = basePredatorDamageRatePerSecond * Double(state.corals[index].activePredators.count)
                let predatorControl = predatorRecruitment * basePredatorControlRatePerSecond
                let netPredatorDamage = max(0.0, basePredation - predatorControl)
                state.corals[index].predatorDamage = min(1.0, state.corals[index].predatorDamage + netPredatorDamage * elapsed)
            }

            // --- D. WATER TEMPERATURE HEAT STRESS (dormant in exhibition — DEC-025) ---
            if threats.waterTemperature > 30.0 {
                state.corals[index].isBleached = true
            } else if state.corals[index].isBleached && !threats.isHeatwaveActive && state.corals[index].algaePercentage < 0.3 {
                state.corals[index].isBleached = false
            }

            // --- E. MORTALITY TRIGGERS (gated by allowDeath for graceful catch-up) ---
            guard allowDeath else { continue }
            // 1. Smothering: bleached, weakened corals die if smothered by algae (>80%)
            if state.corals[index].isBleached && state.corals[index].algaePercentage > 0.8 {
                state.corals[index].isDead = true
            }
            // 2. Tissue Loss: pest mortality is disabled for MVP exploration (DEC-033);
            // pests strictly slow down growth via predatorModifier in section A.
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
