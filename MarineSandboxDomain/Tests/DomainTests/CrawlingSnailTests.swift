import Foundation
import Testing
@testable import Domain

@Suite("CrawlingSnail")
struct CrawlingSnailTests {
    @Test func identifiesLeftwardTravelFromRightSpawn() {
        let snail = CrawlingSnail(targetFragID: UUID(), startX: 500, targetX: 200, targetY: 0)
        #expect(snail.isMovingLeft)
    }

    @Test func preservesDefaultOrientationForRightwardTravel() {
        let snail = CrawlingSnail(targetFragID: UUID(), startX: 200, targetX: 500, targetY: 0)
        #expect(!snail.isMovingLeft)
    }
}
