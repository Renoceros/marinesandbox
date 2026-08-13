import Foundation

public struct ThreatVector {
    public var agriculturalRunoff: Bool
    public var isHeatwaveActive: Bool
    public var waterTemperature: Double
    
    public init(agriculturalRunoff: Bool = false, isHeatwaveActive: Bool = false, waterTemperature: Double = 27.0) {
        self.agriculturalRunoff = agriculturalRunoff
        self.isHeatwaveActive = isHeatwaveActive
        self.waterTemperature = waterTemperature
    }
}
