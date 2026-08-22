import CoreGraphics
import Foundation
import SwiftData
import SwiftUI

// MARK: - Planting & Guided Cold Open (DEC-009, DEC-024)

extension SandboxViewModel {

    /// Phase of the guided cold open, for the view's highlight/pulse states.
    public enum GuidedPlantPhase: Sendable {
        /// Rubble is covering the survivor frag; user must flick rubble away.
        case awaitingRubbleClear
        /// Rubble cleared; waiting for the user to tap and lift the survivor frag.
        case awaitingFragTap
        /// Frag lifted; the seabed target zone is pulsing.
        case awaitingPlant
        /// Planted. The steady-state care loop begins.
        case done
    }

    /// The survivor frag from the cold open (nil once the guide is done or if absent).
    public var survivorFrag: CoralFrag? {
        guard let canvas, !canvas.guidedPlantDone else { return nil }
        return canvas.coralFrags.first { !$0.isDead }
    }

    /// Current guide phase, derived from persisted state so an interrupted cold
    /// open resumes correctly on relaunch.
    public var guidedPlantPhase: GuidedPlantPhase {
        if canvas?.guidedPlantDone == true { return .done }
        if !isSurvivorUncovered { return .awaitingRubbleClear }
        return liftedFragID == nil ? .awaitingFragTap : .awaitingPlant
    }

    /// True when the player has cleared enough rubble to expose the living survivor frag.
    public var isSurvivorUncovered: Bool {
        rubblePieces.isEmpty || rubblePieces.filter { !$0.isCleared }.count <= 1
    }

    /// Sets up the initial rubble pile covering the survivor fragment if not yet planted.
    public func setupRubblePileIfNeeded() {
        guard let canvas, !canvas.guidedPlantDone else {
            rubblePieces.removeAll()
            return
        }
        if rubblePieces.isEmpty {
            rubblePieces = [
                RubblePiece(assetName: "Fragment1", offset: CGPoint(x: -36, y: -24), rotation: -18),
                RubblePiece(assetName: "Fragment2", offset: CGPoint(x: 44, y: -16), rotation: 28),
                RubblePiece(assetName: "Fragment3", offset: CGPoint(x: -16, y: -48), rotation: -10),
                RubblePiece(assetName: "Fragment4", offset: CGPoint(x: 36, y: 32), rotation: 36),
                RubblePiece(assetName: "Fragment1", offset: CGPoint(x: 4, y: -12), rotation: 8),
                RubblePiece(assetName: "Fragment2", offset: CGPoint(x: -48, y: 16), rotation: -30)
            ]
        }
    }

    /// Flicks a dead rubble piece off-screen with velocity and sound feedback.
    public func flickRubble(id: UUID, velocity: CGPoint) {
        guard let index = rubblePieces.firstIndex(where: { $0.id == id }) else { return }
        AudioPlayerService.shared.playSFX("pest_flick")
        let speed = max(Physics.flickThreshold, (velocity.x * velocity.x + velocity.y * velocity.y).squareRoot())
        let normalized = speed > 0 ? CGPoint(x: velocity.x / speed, y: velocity.y / speed) : CGPoint(x: 0, y: -1)
        let throwDist = 600.0
        rubblePieces[index].isFlicked = true
        rubblePieces[index].flickTargetOffset = CGPoint(
            x: rubblePieces[index].offset.x + normalized.x * throwDist,
            y: rubblePieces[index].offset.y + normalized.y * throwDist
        )
        rubblePieces[index].rotation += Double.random(in: 180...360) * (normalized.x >= 0 ? 1 : -1)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self, let idx = self.rubblePieces.firstIndex(where: { $0.id == id }) else { return }
            self.rubblePieces[idx].isCleared = true
            if self.isSurvivorUncovered {
                AudioPlayerService.shared.playSFX("sparkle_clean")
            }
        }
    }

    /// Lifts the survivor frag on tap (guide step 1: frag highlights).
    public func liftSurvivorFrag() {
        guard let survivor = survivorFrag else { return }
        liftFrag(id: survivor.id)
    }

    /// Lifts any frag by id, so it follows the finger until it is dropped.
    public func liftFrag(id: UUID) {
        guard let frag = canvas?.coralFrags.first(where: { $0.id == id }) else { return }
        liftedFragID = id
        liftedFragPosition = CGPoint(x: frag.xPos, y: frag.yPos)
        AudioPlayerService.shared.playSFX("frag_lift")
    }

    /// Drags the lifted frag to a canvas-space point.
    public func dragLiftedFrag(to point: CGPoint) {
        liftedFragPosition = point
    }

    /// Drops the lifted frag (plant + settle feedback). Clamped to playable bounds.
    public func plantLiftedFrag() {
        guard let canvas, let id = liftedFragID,
              let frag = canvas.coralFrags.first(where: { $0.id == id }) else { return }
        let drop = Physics.clampedDrop(liftedFragPosition, canvasWidth: canvas.canvasWidth)
        frag.xPos = drop.x
        frag.yPos = restingHeight(forDropHeight: liftedFragPosition.y, atX: drop.x)
        canvas.guidedPlantDone = true
        liftedFragID = nil
        rubblePieces.removeAll()
        AudioPlayerService.shared.playSFX("frag_plant")
        save()
    }

    /// Tapping the glowing zone instead of dragging: the frag auto-flies there.
    public func autoPlantSurvivor(at point: CGPoint) {
        guard let survivor = survivorFrag else { return }
        liftedFragID = survivor.id
        liftedFragPosition = point
        plantLiftedFrag()
    }

    /// Plants a frag on the seabed at a canvas-space point (DEC-024: direct planting).
    @discardableResult
    public func plantFrag(species: String, at point: CGPoint) -> CoralFrag? {
        guard let canvas, config.availableSpecies.contains(species) else { return nil }
        let drop = Physics.clampedDrop(point, canvasWidth: canvas.canvasWidth)
        let frag = CoralFrag(species: species, xPos: drop.x, yPos: drop.y)
        modelContext.insert(frag)
        canvas.coralFrags.append(frag)
        save()
        return frag
    }

    /// Settles an already-planted frag down onto the sand.
    public func settleFrag(id: UUID, fromDropHeight dropHeight: Double) {
        guard let frag = canvas?.coralFrags.first(where: { $0.id == id }) else { return }
        frag.yPos = restingHeight(forDropHeight: dropHeight, atX: frag.xPos)
        save()
    }

    /// Where a frag released at `dropHeight` above the container floor settles.
    public func restingHeight(forDropHeight dropHeight: Double, atX x: Double) -> Double {
        let surface = SeabedProfile.shared.surfaceHeight(
            atLayerX: CGFloat(x),
            blockWidth: seabedBlockWidth
        ) ?? Double(seabedFallbackHeight)

        return ParallaxMetrics.restingHeight(dropHeight: dropHeight, surfaceHeight: surface)
    }

    /// Resets the canvas back to the cold open state with unplanted survivor frag and rubble.
    public func resetToColdOpen() {
        guard let canvas else { return }
        canvas.guidedPlantDone = false
        liftedFragID = nil
        rubblePieces.removeAll()
        crawlingSnails.removeAll()
        rewardedTeenageCoralIDs.removeAll()
        for frag in canvas.coralFrags { modelContext.delete(frag) }
        canvas.coralFrags.removeAll()

        let survivor = CoralFrag(
            species: "Acropora",
            xPos: 120,
            yPos: 35,
            growthProgress: 0.0
        )
        modelContext.insert(survivor)
        canvas.coralFrags.append(survivor)
        setupRubblePileIfNeeded()
        save()
    }

    /// Clears the reef down to one healthy coral in the middle of the field (Playground mode).
    public func resetToSinglePlaygroundFrag() {
        guard let canvas else { return }
        canvas.guidedPlantDone = true
        liftedFragID = nil
        rubblePieces.removeAll()
        showPestTooltip = false

        let isAlreadyCleanField = canvas.coralFrags.count == 1
            && canvas.coralFrags.allSatisfy { !$0.isDead }

        if !isAlreadyCleanField {
            for frag in canvas.coralFrags { modelContext.delete(frag) }
            canvas.coralFrags.removeAll()

            let frag = CoralFrag(
                species: "Acropora",
                xPos: canvas.canvasWidth / 2,
                yPos: 0,
                growthProgress: 0.0
            )
            modelContext.insert(frag)
            canvas.coralFrags.append(frag)
        }
        save()
    }
}
