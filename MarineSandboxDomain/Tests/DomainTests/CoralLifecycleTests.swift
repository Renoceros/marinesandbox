import Testing
@testable import Domain

@Suite("CoralLifecycle")
struct CoralLifecycleTests {
    @Test func mapsStageBoundariesToLottieFrames() {
        #expect(CoralLifecycle.frame(for: 0) == 0)
        #expect(CoralLifecycle.frame(for: 1) == 59)
    }

    @Test func mapsProgressWithinEachPhase() {
        #expect(abs(CoralLifecycle.frame(for: 0.25) - 14.75) < 0.0001)
        #expect(abs(CoralLifecycle.frame(for: 0.5) - 29.5) < 0.0001)
        #expect(abs(CoralLifecycle.frame(for: 0.75) - 44.25) < 0.0001)
    }

    @Test func findsTheNextLifecycleBoundary() {
        #expect(CoralLifecycle.nextPhaseProgress(after: 0) == 0.25)
        #expect(CoralLifecycle.nextPhaseProgress(after: 0.25) == 0.50)
        #expect(CoralLifecycle.nextPhaseProgress(after: 0.50) == 0.75)
        #expect(CoralLifecycle.nextPhaseProgress(after: 0.75) == 1.0)
    }
}
