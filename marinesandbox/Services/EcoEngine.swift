import Foundation
import SwiftData

/// **EcoEngine: The Stateless Math Simulator**
///
/// This engine processes time-step calculations of the coral reef ecosystem's health.
/// It is designed to be completely stateless—taking the current state of a `ReefCanvas`
/// and environmental `ThreatVector` parameters, and returning an updated `ReefCanvas`
/// representing the next state.
///
/// ### Core Pedagogical Concept:
/// Rather than acting as a scientific simulation, the math illustrates key ecological principles
/// implicitly (subliminally) through gameplay mechanics:
/// 1. **Biodiversity promotes resilience:** Higher Shannon Index ($H$) boosts herbivorous fish recruitment,
///    which automates algae removal. In a monoculture ($H = 0$), no automated help is recruited,
///    forcing players to manually clean algae.
/// 2. **Fragility of Bleached Corals:** Weakened bleached corals die if smothered by algae ($>80\%$),
///    demonstrating that global temperature stresses require local ecosystem health to survive.
///
public struct EcoEngine {
    
    // MARK: - Environmental Constants
    
    /// Modulates how strongly the Shannon Index ($H$) impacts fish recruitment.
    /// Higher values increase the efficiency multiplier of recruited helper fish.
    public static let beta: Double = 0.5
    
    /// Baseline growth progress added to healthy coral fragments per month.
    /// (Takes approximately 12 months for a healthy coral to reach maturity).
    public static let baseGrowthRate: Double = 0.08
    
    /// Baseline rate at which algae grows and spreads on structures.
    public static let baseAlgaeGrowthRate: Double = 0.06
    
    /// Baseline algae grazing capacity per recruited herbivore unit per month.
    public static let baseGrazingRate: Double = 0.03
    
    /// Baseline rate of tissue consumption per active pest (e.g. Drupella snail).
    public static let basePredatorDamageRate: Double = 0.05
    
    /// Efficiency of recruited predatory fish (e.g. wrasses) in controlling pests.
    public static let basePredatorControlRate: Double = 0.04
    
    // MARK: - Simulation Loop
    
    /// Advances the canvas state forward by a specified number of simulation months.
    ///
    /// - Parameters:
    ///   - canvas: The current `ReefCanvas` containing structures and coral fragments.
    ///   - threats: Active environmental parameters (temperatures, run-off shocks).
    ///   - steps: Number of months to calculate (1 for active play ticks, 60 for timelapse sweeps).
    /// - Returns: The updated `ReefCanvas` reference after applying updates.
    ///
    public static func updateState(
        canvas: ReefCanvas,
        threats: ThreatVector,
        steps: Int
    ) -> ReefCanvas {
        for _ in 0..<steps {
            
            // 1. Calculate Shannon Diversity Index (H)
            // Measures species layout variety to determine helper fish recruitment efficiency
            let H = calculateShannonIndex(for: canvas)
            
            // 2. Count Active Coral Growth Stages to Recruit Visual Fauna
            // Growing corals attract specific fish populations to the midground
            var herbivoreCount = 0
            var predatorCount = 0
            
            for coral in canvas.coralFrags {
                guard !coral.isDead else { continue }
                
                if coral.isAdult {
                    // Adult corals recruit grazing surgeonfish and pest-eating wrasses
                    herbivoreCount += 1
                    predatorCount += 1
                }
            }
            
            // Recruited grazing & pest control rates, scaled by biodiversity index H
            let herbivoreRecruitment = Double(herbivoreCount) * (1.0 + beta * H)
            let predatorRecruitment = Double(predatorCount) * (1.0 + beta * H)
            
            // 3. Process Individual Biological Coral Fragments
            for coral in canvas.coralFrags {
                if coral.isDead { continue }
                
                // --- A. GROWTH CONSTRAINTS ---
                // Growth is slowed down proportionally by active algae coverage and predator damage
                let algaeSmotherModifier = max(0.0, 1.0 - coral.algaePercentage)
                let predatorModifier = max(0.0, 1.0 - coral.predatorDamage)
                
                let growthIncrement = baseGrowthRate * algaeSmotherModifier * predatorModifier
                coral.growthProgress = min(1.0, coral.growthProgress + growthIncrement)
                
                // --- B. ALGAE VS. GRAZER DYNAMICS ---
                // Agricultural runoff multiplies algae growth rate.
                // Baby & Teenager stages are highly vulnerable and grow algae faster.
                let nutrientInflow = threats.agriculturalRunoff ? 2.5 : 1.0
                let baseAlgaeRate = (coral.isBaby || coral.isTeenager) ? baseAlgaeGrowthRate * 1.5 : baseAlgaeGrowthRate
                let algaeGrowth = baseAlgaeRate * nutrientInflow
                let grazingRate = herbivoreRecruitment * baseGrazingRate
                
                // Net change in algae percentage (clamped [0, 1])
                coral.algaePercentage = max(0.0, min(1.0, coral.algaePercentage + algaeGrowth - grazingRate))
                
                // --- C. PEST PREDATION DYNAMICS ---
                // activePredators counts active snails on this structure.
                // Predatory fish (wrasses) mitigate pest damage.
                if !coral.activePredators.isEmpty {
                    let basePredation = basePredatorDamageRate * Double(coral.activePredators.count)
                    let predatorControl = predatorRecruitment * basePredatorControlRate
                    let netPredatorDamage = max(0.0, basePredation - predatorControl)
                    
                    coral.predatorDamage = min(1.0, coral.predatorDamage + netPredatorDamage)
                }
                
                // --- D. WATER TEMPERATURE HEAT STRESS ---
                // Water temperatures above 30C trigger bleaching (zooxanthellae ejection).
                if threats.waterTemperature > 30.0 {
                    coral.isBleached = true
                } else if coral.isBleached && !threats.isHeatwaveActive && coral.algaePercentage < 0.3 {
                    // Bleached corals recover only if heatwaves end and algae levels are low (<30%)
                    coral.isBleached = false
                }
                
                // --- E. MORTALITY TRIGGERS ---
                // 1. Smothering: Bleached weakened corals die if smothered by algae (>80%)
                if coral.isBleached && coral.algaePercentage > 0.8 {
                    coral.isDead = true
                }
                // 2. Tissue Loss: Corals die if predator damage reaches 100%
                if coral.predatorDamage >= 1.0 {
                    coral.isDead = true
                }
            }
        }
        
        return canvas
    }
    
    // MARK: - Mathematical Helpers
    
    /// Computes the Shannon Entropy Index for the canvas:
    /// $$H = -\sum (p_i \ln p_i)$$
    /// where $p_i$ is the relative proportion of living coral fragments belonging to species $i$.
    ///
    public static func calculateShannonIndex(for canvas: ReefCanvas) -> Double {
        let activeCorals = canvas.coralFrags.filter { !$0.isDead }
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
