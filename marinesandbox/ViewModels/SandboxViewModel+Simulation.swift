import Foundation
import SwiftData

// MARK: - Simulation, Speed Controls, & Fast Forward (DEC-007, DEC-020, DEC-031, DEC-038)

extension SandboxViewModel {

    /// Live refresh slice in real seconds (DEC-031).
    public static let tickInterval: TimeInterval = 1.0

    /// Exhibition Fast Forward jump in real seconds (DEC-031).
    public static let fastForwardInterval: TimeInterval = 2 * 24 * 60 * 60

    /// Pest spawn probability per second per eligible coral (DEC-028, DEC-031).
    public static let pestSpawnChancePerSecond: Double = 1.0 / (12 * 60 * 60)
    public static let pestCapPerCoral = 2

    /// Current effective simulation speed multiplier.
    public var effectiveSimMultiplier: Double {
        if isDebug100xActive { return 100.0 }
        if fastForwardRemainingSeconds > 0 { return 10.0 }
        return 1.0
    }

    /// True when 10x fast forward boost is currently active.
    public var isFastForward10xActive: Bool { fastForwardRemainingSeconds > 0 }

    /// Activates the 10x simulation speed boost for the given duration (default: 30s).
    public func activate10xFastForward(duration: Double = 30.0) {
        fastForwardRemainingSeconds = duration
        AudioPlayerService.shared.playSFX("sparkle_clean")
    }

    /// Sets whether debug 100x speed hold is active.
    public func setDebug100xActive(_ active: Bool) {
        guard isDebug100xActive != active else { return }
        isDebug100xActive = active
        if active {
            AudioPlayerService.shared.playSFX("frag_lift")
        }
    }

    public func completeLottiePlayback(for coralID: UUID) {
        lottiePlaybackTargets[coralID] = nil
    }

    /// Advances the reef by one live refresh slice of real time (DEC-031).
    public func tick(elapsed: TimeInterval? = nil) {
        let span = elapsed ?? Self.tickInterval
        commit(EcoEngine.advance(state: snapshot(), threats: threats, elapsed: span, allowDeath: true))
    }

    /// One live refresh slice: engine advance + pest spawning. Driven by view timer.
    public func tickLive(dt: TimeInterval? = nil) {
        let step = dt ?? Self.tickInterval
        if fastForwardRemainingSeconds > 0 {
            fastForwardRemainingSeconds = max(0, fastForwardRemainingSeconds - step)
        }
        guard canvas?.guidedPlantDone == true else { return }
        let simSpeedMultiplier = effectiveSimMultiplier * 4500.0
        let scaledElapsed = step * simSpeedMultiplier
        tick(elapsed: scaledElapsed)
        spawnPestsIfNeeded(elapsed: step)
        advanceCrawlingSnails(dt: step)
        checkTeenageSpawns()
    }

    /// Advances every coral by `fastForwardInterval` of wall time (DEC-031).
    public func performFastForward() {
        let before = snapshot()
        var outcome = EcoEngine.advance(
            state: before,
            threats: threats,
            elapsed: Self.fastForwardInterval,
            allowDeath: true
        )
        for index in outcome.corals.indices where !outcome.corals[index].isDead {
            outcome.corals[index].growthProgress = max(
                outcome.corals[index].growthProgress,
                CoralLifecycle.nextPhaseProgress(after: before.corals[index].growthProgress)
            )
        }
        commit(outcome)
        lottiePlaybackTargets = Dictionary(uniqueKeysWithValues: outcome.corals.map { ($0.id, $0.growthProgress) })
        spawnPestsIfNeeded(elapsed: Self.fastForwardInterval)
        checkTeenageSpawns()
        pendingDiagnostic = outcome
        diagnosticMessage = Self.diagnose(before: before, after: outcome)
    }

    /// Spawns a new random living coral fragment floating in open water whenever a coral reaches Teenage phase.
    public func checkTeenageSpawns() {
        guard let canvas, canvas.guidedPlantDone else { return }
        for frag in canvas.coralFrags {
            guard !frag.isDead, (frag.isTeenager || frag.isAdult), !rewardedTeenageCoralIDs.contains(frag.id) else { continue }
            rewardedTeenageCoralIDs.insert(frag.id)

            let allSpecies = config.availableSpecies.isEmpty
                ? ["Acropora", "BrainCoral", "ElkhornCoral", "SpongeCoral", "StaghornCoral", "TableCoral"]
                : config.availableSpecies
            let species = allSpecies.randomElement() ?? "Acropora"

            let spawnX = min(max(80.0, frag.xPos + Double.random(in: -140...140)), canvas.canvasWidth - 80.0)
            let floatingFrag = CoralFrag(
                species: species,
                xPos: spawnX,
                yPos: 240.0,
                growthProgress: 0.0
            )
            modelContext.insert(floatingFrag)
            canvas.coralFrags.append(floatingFrag)
            AudioPlayerService.shared.playSFX("sparkle_clean")
        }
        save()
    }

    /// Dismisses the Diagnostic Card.
    public func dismissDiagnostic() {
        pendingDiagnostic = nil
    }

    public func dismissDiagnosticCard() {
        pendingDiagnostic = nil
        diagnosticMessage = nil
    }

    /// Builds the card's reflection message from the dominant change (DEC-007, DEC-038).
    static func diagnose(before: ReefState, after: ReefState) -> String {
        let beforeLiving = before.livingCorals
        let afterLiving = after.livingCorals
        let deaths = beforeLiving.count - afterLiving.count
        let grew = zip(before.corals, after.corals).filter { $0.growthProgress < 0.7 && $1.growthProgress >= 0.7 }

        if deaths > 0 {
            let algaeDeaths = zip(before.corals, after.corals).filter { !$0.isDead && $1.isDead && $1.algaePercentage > 0.8 }
            if !algaeDeaths.isEmpty {
                return "Some corals were smothered by algae. Young corals need regular brushing until they're strong enough to attract helper fish."
            }
            return "Some corals didn't survive the pests. Snails and starfish eat coral tissue — remove them before the damage is done."
        }
        if !grew.isEmpty {
            return "Your reef matured! Adult corals now attract fish that clean algae and eat pests for you. A healthy reef takes care of itself."
        }
        let avgAlgae = afterLiving.map(\.algaePercentage).reduce(0, +) / Double(max(afterLiving.count, 1))
        if avgAlgae > 0.5 {
            return "Algae is winning. Without brushing, it blocks the light your corals need to grow."
        }
        return "Your reef held steady. Plant a mix of species — diverse reefs recover from shocks that wipe out monocultures."
    }
}
