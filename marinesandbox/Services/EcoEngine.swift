import Foundation
import SwiftData

public struct EcoEngine {
    // Model Constants
    public static let beta: Double = 0.5
    public static let baseGrowthRate: Double = 0.08
    public static let baseAlgaeGrowthRate: Double = 0.06
    public static let baseGrazingRate: Double = 0.03
    public static let basePredatorDamageRate: Double = 0.05
    public static let basePredatorControlRate: Double = 0.04
    
    public static func updateState(
        canvas: ReefCanvas,
        threats: ThreatVector,
        steps: Int
    ) -> ReefCanvas {
        for _ in 0..<steps {
            // 1. Calculate Shannon Diversity Index (H)
            let H = calculateShannonIndex(for: canvas)
            
            // 2. Calculate Fauna Recruitment counts based on growth stages
            var smallReefFishCount = 0
            var gobiesAndDamselfishCount = 0
            var largeSchoolsCount = 0
            var herbivoreCount = 0
            var predatorCount = 0
            
            for structure in canvas.placedStructures {
                guard let coral = structure.coral, !coral.isDead else { continue }
                if coral.isBaby {
                    smallReefFishCount += 1
                } else if coral.isTeenager {
                    gobiesAndDamselfishCount += 1
                } else if coral.isAdult {
                    largeSchoolsCount += 1
                    herbivoreCount += 1
                    predatorCount += 1 // Wrasses / triggerfish attracted by adult corals
                }
            }
            
            // Modulate grazing rate and predator control based on fish counts and Shannon Index H
            let herbivoreRecruitment = Double(herbivoreCount) * (1.0 + beta * H)
            let predatorRecruitment = Double(predatorCount) * (1.0 + beta * H)
            
            // 3. Process placed structures
            for structure in canvas.placedStructures {
                guard let coral = structure.coral else { continue }
                if coral.isDead { continue }
                
                // Growth calculation adjusted by algae overgrowth and predator damage
                let algaeSmotherModifier = max(0.0, 1.0 - coral.algaePercentage)
                let predatorModifier = max(0.0, 1.0 - coral.predatorDamage)
                
                let growthIncrement = baseGrowthRate * algaeSmotherModifier * predatorModifier
                coral.growthProgress = min(1.0, coral.growthProgress + growthIncrement)
                
                // Process Algae growth vs Grazer control (Baby/Teenager phases are most vulnerable)
                let nutrientInflow = threats.agriculturalRunoff ? 2.5 : 1.0
                let baseAlgaeRate = (coral.isBaby || coral.isTeenager) ? baseAlgaeGrowthRate * 1.5 : baseAlgaeGrowthRate
                let algaeGrowth = baseAlgaeRate * nutrientInflow
                let grazingRate = herbivoreRecruitment * baseGrazingRate
                coral.algaePercentage = max(0.0, min(1.0, coral.algaePercentage + algaeGrowth - grazingRate))
                
                // Process Predator infestations (Crown-of-Thorns, Drupella snails, flatworms)
                if !coral.activePredators.isEmpty {
                    // Predation rate increases damage, offset by recruited predatory fish (e.g. wrasses)
                    let basePredation = basePredatorDamageRate * Double(coral.activePredators.count)
                    let predatorControl = predatorRecruitment * basePredatorControlRate
                    let netPredatorDamage = max(0.0, basePredation - predatorControl)
                    coral.predatorDamage = min(1.0, coral.predatorDamage + netPredatorDamage)
                }
                
                // Process Heat stress (Bleaching)
                if threats.waterTemperature > 30.0 {
                    coral.isBleached = true
                } else if coral.isBleached && !threats.isHeatwaveActive && coral.algaePercentage < 0.3 {
                    coral.isBleached = false
                }
                
                // Mortality checks
                // 1. Smothered: If bleached coral is smothered by algae, it dies
                if coral.isBleached && coral.algaePercentage > 0.8 {
                    coral.isDead = true
                }
                // 2. Predator Overconsumption: If predators consume more than 100% of tissue
                if coral.predatorDamage >= 1.0 {
                    coral.isDead = true
                }
            }
        }
        
        return canvas
    }
    
    public static func calculateShannonIndex(for canvas: ReefCanvas) -> Double {
        let activeCorals = canvas.placedStructures.compactMap { $0.coral }.filter { !$0.isDead }
        guard !activeCorals.isEmpty else { return 0.0 }
        
        // Group by species
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
