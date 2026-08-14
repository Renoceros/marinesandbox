import Foundation

/// **AlgaeCoverage: Spatial Dirt Model (DEC-018)**
///
/// Algae is tracked as a coarse grid over a coral's bounding box rather than a single
/// scalar, because cleaning is a *local* act: the player scrubs a patch and expects
/// that patch to come clean. A scalar can only express "how much" dirt, never "where",
/// which reads on screen as the whole coral flickering instead of the player cleaning it.
///
/// The scalar `percentage` the ecology maths needs is *derived* from the grid, so
/// `EcoEngine` keeps working in aggregate while the view masks per cell.
///
/// ### Coordinate space
/// Strokes arrive in **normalised coral-local space**: `(0, 0)` is the top-left of the
/// coral's bounding box and `(1, 1)` the bottom-right. This keeps the model independent
/// of artwork size, so replacing placeholder art with final Lottie assets cannot break
/// cleaning (DEC-019).
///
/// ### Who drives it
/// Both the brush *and* helper-fish grazing mutate this same grid. Identical visuals,
/// different driver — which is what makes the manual-to-automated reward arc
/// (PRD §3.2) nearly free.
///
public struct AlgaeCoverage: Equatable, Sendable {

    /// Grid is `resolution × resolution`. Six is enough to feel local without making
    /// a single swipe feel like it accomplished nothing.
    public static let resolution = 6

    /// Radius of a brush stroke in normalised units (fraction of the coral's box).
    public static let brushRadius: Double = 0.18

    /// Row-major coverage per cell, `0.0` (clean) to `1.0` (fully smothered).
    /// Row `0` is the top of the coral; the last row sits at its base.
    public private(set) var cells: [Float]

    /// Creates a grid with the same coverage in every cell.
    public init(uniform: Double = 0.0) {
        let clamped = Float(min(max(uniform, 0.0), 1.0))
        self.cells = Array(repeating: clamped, count: Self.resolution * Self.resolution)
    }

    // MARK: - Derived Aggregates

    /// Mean coverage across the grid — the scalar the ecology maths consumes.
    public var percentage: Double {
        Double(cells.reduce(0, +)) / Double(cells.count)
    }

    /// True when no cell holds any algae, i.e. the coral is visually spotless.
    public var isClean: Bool { cells.allSatisfy { $0 <= 0 } }

    // MARK: - Ecology Drivers

    /// Grows algae, biased toward the base of the coral.
    ///
    /// Algae colonises the dead skeleton at the base first and creeps upward, so lower
    /// rows accumulate faster. Weights average to `1.0`, keeping the aggregate rate
    /// equal to the scalar rate `EcoEngine` asks for.
    public mutating func grow(by amount: Double) {
        guard amount > 0 else { return }
        for index in cells.indices {
            let row = index / Self.resolution
            let bias = 0.5 + Double(row) / Double(Self.resolution - 1)
            cells[index] = clamp(cells[index] + Float(amount * bias))
        }
    }

    /// Removes algae the way grazing fish do: thickest patches first.
    ///
    /// `amount` is a per-cell average, so a budget of `amount × cellCount` is spent
    /// across the grid. Ordering is deterministic (coverage descending, then index) so
    /// simulations stay reproducible.
    public mutating func graze(by amount: Double) {
        guard amount > 0 else { return }
        var budget = amount * Double(cells.count)
        let order = cells.indices.sorted { lhs, rhs in
            cells[lhs] == cells[rhs] ? lhs < rhs : cells[lhs] > cells[rhs]
        }
        for index in order {
            guard budget > 0 else { break }
            let taken = min(Double(cells[index]), budget)
            cells[index] = clamp(cells[index] - Float(taken))
            budget -= taken
        }
    }

    // MARK: - Player Interaction

    /// Clears algae along a brush stroke, returning the cells that just became clean.
    ///
    /// Takes a **segment**, not a point, on purpose: `DragGesture` reports discrete
    /// locations and a fast swipe can jump a long way between callbacks. Interpolating
    /// along the segment is what stops fast swipes from leaving uncleaned stripes.
    ///
    /// - Returns: indices that transitioned from dirty to clean, for sparkles and haptics.
    @discardableResult
    public mutating func clear(
        from start: CGPoint,
        to end: CGPoint,
        radius: Double = AlgaeCoverage.brushRadius
    ) -> [Int] {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let distance = (dx * dx + dy * dy).squareRoot()

        // Step at half the brush radius so consecutive samples always overlap.
        let stride = max(radius / 2, 0.001)
        let samples = max(1, Int((distance / stride).rounded(.up)))

        var cleared: [Int] = []
        for sample in 0...samples {
            let t = samples == 0 ? 0 : Double(sample) / Double(samples)
            let point = CGPoint(x: start.x + dx * t, y: start.y + dy * t)
            cleared.append(contentsOf: clear(around: point, radius: radius))
        }
        return cleared
    }

    /// Clears every cell whose centre falls within `radius` of `point`.
    private mutating func clear(around point: CGPoint, radius: Double) -> [Int] {
        var cleared: [Int] = []
        for index in cells.indices where cells[index] > 0 {
            let (x, y) = Self.center(of: index)
            let dx = x - Double(point.x)
            let dy = y - Double(point.y)
            if (dx * dx + dy * dy).squareRoot() <= radius {
                cells[index] = 0
                cleared.append(index)
            }
        }
        return cleared
    }

    // MARK: - Geometry

    /// Centre of a cell in normalised coral-local space.
    public static func center(of index: Int) -> (x: Double, y: Double) {
        let row = index / resolution
        let column = index % resolution
        return (
            x: (Double(column) + 0.5) / Double(resolution),
            y: (Double(row) + 0.5) / Double(resolution)
        )
    }

    /// Coverage of a single cell, or `0` when the index is out of range.
    public func coverage(at index: Int) -> Float {
        cells.indices.contains(index) ? cells[index] : 0
    }

    private func clamp(_ value: Float) -> Float { min(max(value, 0), 1) }
}
