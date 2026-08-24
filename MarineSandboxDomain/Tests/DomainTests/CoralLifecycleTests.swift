import Testing
@testable import Domain

@Suite("CoralLifecycle")
struct CoralLifecycleTests {
    @Test func mapsStaghornStageBoundariesToLottieFrames() {
        #expect(CoralLifecycle.frame(for: 0, species: "Acropora") == 0)
        #expect(CoralLifecycle.frame(for: 1, species: "Acropora") == 59)
    }

    @Test func mapsStaghornProgressWithinEachPhase() {
        #expect(abs(CoralLifecycle.frame(for: 0.25, species: "Acropora") - 14.75) < 0.0001)
        #expect(abs(CoralLifecycle.frame(for: 0.5, species: "Acropora") - 29.5) < 0.0001)
        #expect(abs(CoralLifecycle.frame(for: 0.75, species: "Acropora") - 44.25) < 0.0001)
    }

    @Test func mapsBrainCoralMaturityToFinalFrame() {
        #expect(CoralLifecycle.frame(for: 1, species: "BrainCoral") == 599)
    }

    @Test func findsTheNextLifecycleBoundary() {
        #expect(CoralLifecycle.nextPhaseProgress(after: 0) == 0.25)
        #expect(CoralLifecycle.nextPhaseProgress(after: 0.25) == 0.50)
        #expect(CoralLifecycle.nextPhaseProgress(after: 0.50) == 0.75)
        #expect(CoralLifecycle.nextPhaseProgress(after: 0.75) == 1.0)
    }
}
