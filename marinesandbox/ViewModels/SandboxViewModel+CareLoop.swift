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
        var coverage = AlgaeCoverage(cells: frag.algaeCells)
        let cleared = coverage.clear(from: start, to: end)
        frag.algaeCells = coverage.cells
        save()
        return cleared
    }

    // MARK: Pests & Snails (DEC-028, DEC-012, DEC-034)

    /// Spawns Drupella snails crawling from off-screen margins toward eligible corals (DEC-034).
    public func spawnPestsIfNeeded(
        elapsed: TimeInterval,
        random: Double = Double.random(in: 0...1)
    ) {
        guard let canvas, elapsed > 0 else { return }
        let chance = min(1.0, Self.pestSpawnChancePerSecond * elapsed * 2.0)
        for frag in canvas.coralFrags {
            guard !frag.isDead, frag.isBaby || frag.isTeenager else { continue }
            let existingCount = frag.activePredators.count + crawlingSnails.filter({ $0.targetFragID == frag.id }).count
            guard existingCount < Self.pestCapPerCoral, random < chance else { continue }

            let fromLeft = Bool.random()
            let startX = fromLeft ? max(20.0, frag.xPos - 350.0) : min(canvas.canvasWidth - 20.0, frag.xPos + 350.0)
            let snail = CrawlingSnail(
                targetFragID: frag.id,
                startX: startX,
                targetX: frag.xPos,
                targetY: frag.yPos
            )
            crawlingSnails.append(snail)
            if frag.activePredators.isEmpty && crawlingSnails.count == 1 {
                showPestTooltip = true
            }
        }
    }

    /// Advances crawling snails along the seabed into their target corals.
    public func advanceCrawlingSnails(dt: TimeInterval) {
        guard let canvas else { return }
        var arrivedIndices: [Int] = []
        for i in crawlingSnails.indices {
            crawlingSnails[i].progress += dt / 3.0
            let p = min(1.0, crawlingSnails[i].progress)
            crawlingSnails[i].currentX = crawlingSnails[i].startX + (crawlingSnails[i].targetX - crawlingSnails[i].startX) * p
            if p >= 1.0 {
                crawlingSnails[i].isArrived = true
                if let frag = canvas.coralFrags.first(where: { $0.id == crawlingSnails[i].targetFragID }) {
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

    /// Removes a crawling snail before it attaches to the coral (tap/flick).
    public func removeCrawlingSnail(id: UUID) {
        crawlingSnails.removeAll(where: { $0.id == id })
        AudioPlayerService.shared.playSFX("pest_smush")
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
        save()
        return pest
    }

    /// Taps a pest to smush it (DEC-012).
    @discardableResult
    public func smushPest(_ pest: String, on fragID: UUID) -> Bool {
        guard let frag = canvas?.coralFrags.first(where: { $0.id == fragID }),
              let index = frag.activePredators.firstIndex(of: pest) else { return false }
        frag.activePredators.remove(at: index)
        save()
        return true
    }

    /// Removes a pest via the Hand tool (DEC-012).
    @discardableResult
    public func flickPest(_ pest: String, velocity: CGPoint, on fragID: UUID) -> Bool {
        _ = Physics.isFlick(velocity: velocity)
        return smushPest(pest, on: fragID)
    }

    /// Toggles an agricultural runoff shock for the session.
    public func setRunoffShock(_ active: Bool) {
        guard config.runoffShockAllowed else { return }
        threats.agriculturalRunoff = active
    }
}
