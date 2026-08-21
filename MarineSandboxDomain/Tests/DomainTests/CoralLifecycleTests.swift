import Testing
@testable import Domain

@Suite("CoralLifecycle")
struct CoralLifecycleTests {
    @Test func mapsStageBoundariesToLottieFrames() {
        #expect(CoralLifecycle.frame(for: 0) == 0)
        #expect(CoralLifecycle.frame(for: 0.3) == 20)
        #expect(CoralLifecycle.frame(for: 0.7) == 40)
        #expect(CoralLifecycle.frame(for: 1) == 59)
    }

    @Test func mapsProgressWithinEachPhase() {
        #expect(abs(CoralLifecycle.frame(for: 0.15) - 10) < 0.0001)
        #expect(abs(CoralLifecycle.frame(for: 0.5) - 30) < 0.0001)
        #expect(abs(CoralLifecycle.frame(for: 0.85) - 49.5) < 0.0001)
    }

    @Test func findsTheNextLifecycleBoundary() {
        #expect(CoralLifecycle.nextPhaseProgress(after: 0) == 0.3)
        #expect(CoralLifecycle.nextPhaseProgress(after: 0.3) == 0.7)
        #expect(CoralLifecycle.nextPhaseProgress(after: 0.7) == 1)
    }
}
