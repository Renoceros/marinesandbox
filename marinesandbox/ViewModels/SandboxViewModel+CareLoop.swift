import CoreGraphics
import Foundation
import SwiftData

// MARK: - Care Loop & Pest Mitigation (DEC-012, DEC-018, DEC-028, DEC-032, DEC-034)

extension SandboxViewModel {

    // MARK: Hit Routing (DEC-026)

    /// The coral under a canvas-space point, if any. Views call this first:
    /// a hit means the active tool owns the gesture; a miss means the drag pans.
    public func coral(atCanvasPoint point: CGPoint, seabedY: Double) -> CoralFrag? {
        guard let canvas else { return nil }
        let snapshots = canvas.coralFrags.map(\.snapshotForInteraction)
        guard let hit = CoralGeometry.hitTest(corals: snapshots, at: point, seabedY: seabedY) else { return nil }
        return canvas.coralFrags.first { $0.id == hit.id }
    }

    // MARK: Brush & Algae (DEC-012, DEC-018)

    /// Applies one brush segment given in canvas space: hit-tests, converts to
    /// coral-local space, clears the crossed cells. Returns cleared cell indices,
    /// empty when the stroke missed every coral.
    @discardableResult
    public func applyBrushSegment(from start: CGPoint, to end: CGPoint, seabedY: Double) -> [Int] {
        guard let frag = coral(atCanvasPoint: start, seabedY: seabedY)
                ?? coral(atCanvasPoint: end, seabedY: seabedY) else { return [] }
        AudioPlayerService.shared.playSFX("brush_swipe", volume: 0.50)
        let snapshot = frag.snapshotForInteraction
        guard let localStart = CoralGeometry.localPoint(in: snapshot, canvasPoint: start, seabedY: seabedY)
                ?? CoralGeometry.localPoint(in: snapshot, canvasPoint: end, seabedY: seabedY),
              let localEnd = CoralGeometry.localPoint(in: snapshot, canvasPoint: end, seabedY: seabedY)
                ?? CoralGeometry.localPoint(in: snapshot, canvasPoint: start, seabedY: seabedY)
        else { return [] }
        return brushStroke(from: localStart, to: localEnd, on: frag.id)
    }

    /// Clears algae along a brush stroke (DEC-012).
    @discardableResult
    public func brushStroke(from start: CGPoint, to end: CGPoint, on fragID: UUID) -> [Int] {
        guard let frag = canvas?.coralFrags.first(where: { $0.id == fragID }) else { return [] }
        let hadAlgae = frag.algaePercentage > 0.05
        var coverage = AlgaeCoverage(cells: frag.algaeCells)
        let cleared = coverage.clear(from: start, to: end)
        if !cleared.isEmpty {
            frag.algaeCells = coverage.cells
            if hadAlgae && frag.algaePercentage <= 0.02 {
                AudioPlayerService.shared.playSFX("sparkle_clean")
            }
            save()
        }
        return cleared
    }

    // MARK: Pests & Snails (DEC-028, DEC-012, DEC-034)

    /// Spawns Drupella snails crawling from off-screen margins toward eligible corals (DEC-034).
    public func spawnPestsIfNeeded(
        elapsed: TimeInterval
    ) {
        guard let canvas, elapsed > 0 else { return }
        let threatMultiplier = threats.agriculturalRunoff ? 2.0 : 1.0
        // Live spawn rate: ~1 spawn attempt every 20s per eligible vulnerable coral during live gameplay
        let chance = min(1.0, (1.0 / 20.0) * elapsed * threatMultiplier)

        var spawnedWave = false
        for frag in canvas.coralFrags {
            // Protect unplanted floating frags and freshly dropped fragments (<0.20 growth) so corals can sprout before pests attack
            guard !frag.isDead, frag.isPlanted, frag.growthProgress >= 0.20, (frag.isBaby || frag.isTeenager) else { continue }
            let existingCount = frag.activePredators.count + crawlingSnails.filter({ $0.targetFragID == frag.id }).count
            guard existingCount < Self.pestCapPerCoral else { continue }
            guard Double.random(in: 0...1) < chance else { continue }

            let fromLeft = Bool.random()
            let startX = fromLeft ? max(20.0, frag.xPos - 280.0) : min(canvas.canvasWidth - 20.0, frag.xPos + 280.0)
            let snail = CrawlingSnail(
                targetFragID: frag.id,
                startX: startX,
                targetX: frag.xPos,
                targetY: frag.yPos
            )
            crawlingSnails.append(snail)
            spawnedWave = true
            if frag.activePredators.isEmpty && crawlingSnails.count == 1 {
                showPestTooltip = true
            }
        }
        if spawnedWave {
            AudioPlayerService.shared.playSFX("threat_warning")
        }
    }

    /// Advances crawling snails along the seabed into their target corals.
    public func advanceCrawlingSnails(dt: TimeInterval) {
        guard let canvas else { return }
        var arrivedIndices: [Int] = []
        for i in crawlingSnails.indices {
            crawlingSnails[i].progress += dt / 7.0
            let p = min(1.0, crawlingSnails[i].progress)
            crawlingSnails[i].currentX = crawlingSnails[i].startX + (crawlingSnails[i].targetX - crawlingSnails[i].startX) * p
            if p >= 1.0 {
                crawlingSnails[i].isArrived = true
                if let frag = canvas.coralFrags.first(where: { $0.id == crawlingSnails[i].targetFragID }), frag.isPlanted, !frag.isDead {
                    if frag.activePredators.count < Self.pestCapPerCoral {
                        frag.activePredators.append("DrupellaSnail")
                    }
                }
                arrivedIndices.append(i)
            }
        }
        if !arrivedIndices.isEmpty {
            crawlingSnails.removeAll(where: { $0.isArrived })
            save()
        }
    }

    /// Removes a crawling snail before it attaches to the coral.
    public func removeCrawlingSnail(id: UUID) {
        crawlingSnails.removeAll(where: { $0.id == id })
        AudioPlayerService.shared.playSFX("pest_smush")
        HapticService.shared.pestSmush()
    }

    public func flickCrawlingSnail(id: UUID, velocity: CGPoint) {
        guard Physics.isFlick(velocity: velocity) else { return }
        crawlingSnails.removeAll(where: { $0.id == id })
        AudioPlayerService.shared.playSFX("pest_flick")
        HapticService.shared.pestFlick()
    }

    public func dismissPestTooltip() {
        showPestTooltip = false
    }

    /// Removes one pest from a coral by index.
    @discardableResult
    public func removePest(at index: Int, on fragID: UUID) -> String? {
        guard let frag = canvas?.coralFrags.first(where: { $0.id == fragID }),
              frag.activePredators.indices.contains(index) else { return nil }
        let pest = frag.activePredators.remove(at: index)
        AudioPlayerService.shared.playSFX("pest_smush")
        HapticService.shared.pestSmush()
        save()
        return pest
    }

    /// Taps a pest to smush it (DEC-012).
    @discardableResult
    public func smushPest(_ pest: String, on fragID: UUID) -> Bool {
        guard let frag = canvas?.coralFrags.first(where: { $0.id == fragID }),
              let index = frag.activePredators.firstIndex(of: pest) else { return false }
        frag.activePredators.remove(at: index)
        AudioPlayerService.shared.playSFX("pest_smush")
        HapticService.shared.pestSmush()
        save()
        return true
    }

    /// Removes a pest via the Hand tool (DEC-012).
    @discardableResult
    public func flickPest(_ pest: String, velocity: CGPoint, on fragID: UUID) -> Bool {
        _ = Physics.isFlick(velocity: velocity)
        guard let frag = canvas?.coralFrags.first(where: { $0.id == fragID }),
              let index = frag.activePredators.firstIndex(of: pest) else { return false }
        frag.activePredators.remove(at: index)
        AudioPlayerService.shared.playSFX("pest_flick")
        HapticService.shared.pestFlick()
        save()
        return true
    }

    public func emitAlgaeDangerWarnings() {
        guard let canvas else { return }
        for frag in canvas.coralFrags where !frag.isDead {
            if frag.algaePercentage >= 0.75, algaeDangerWarningCoralIDs.insert(frag.id).inserted {
                AudioPlayerService.shared.playSFX("threat_warning")
            } else if frag.algaePercentage < 0.75 {
                algaeDangerWarningCoralIDs.remove(frag.id)
            }
        }
    }

    /// Toggles an agricultural runoff shock for the session.
    public func setRunoffShock(_ active: Bool) {
        guard config.runoffShockAllowed else { return }
        threats.agriculturalRunoff = active
    }
}
