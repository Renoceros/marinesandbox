import SwiftUI

/// A pest being flung off-screen (drives throw animation, then removal).
public struct FlyingPest: Equatable, Sendable {
    public let fragID: UUID
    public let pestIndex: Int
    public let start: CGPoint
    public let velocity: CGPoint

    public init(fragID: UUID, pestIndex: Int, start: CGPoint, velocity: CGPoint) {
        self.fragID = fragID
        self.pestIndex = pestIndex
        self.start = start
        self.velocity = velocity
    }
}

/// Pest view using Snail vector asset with tap-to-smush squash and drag-to-flick (DEC-012, DEC-034).
struct PestOverlayView: View {
    @Bindable var viewModel: SandboxViewModel
    let frag: CoralFrag
    let index: Int
    let footprint: CoralGeometry.Footprint

    @Binding var flyingPest: FlyingPest?
    @Binding var smushedPestIDs: Set<String>

    var body: some View {
        let local = CGPoint(x: 0.35 + 0.3 * Double(index), y: 0.4)
        let isFlying = flyingPest?.fragID == frag.id && flyingPest?.pestIndex == index
        let pestKey = "\(frag.id)-\(index)"
        let isSmushed = smushedPestIDs.contains(pestKey)

        Image("Snail")
            .resizable()
            .scaledToFit()
            .frame(width: 36, height: 36)
            .scaleEffect(x: isSmushed ? 1.4 : 1.0, y: isSmushed ? 0.2 : 1.0, anchor: .bottom)
            .opacity(isSmushed ? 0.0 : (isFlying ? 0.9 : 1.0))
            .frame(width: 52, height: 52)
            .contentShape(Rectangle())
            .position(x: local.x * footprint.size.width, y: local.y * footprint.size.height)
            .offset(isFlying ? flyOffset(for: flyingPest) : .zero)
            .highPriorityGesture(
                TapGesture()
                    .onEnded {
                        handlePestTap(fragID: frag.id, index: index)
                    }
            )
            .highPriorityGesture(
                DragGesture(minimumDistance: 4)
                    .onEnded { value in
                        let velocity = CGPoint(x: value.velocity.width, y: value.velocity.height)
                        guard Physics.isFlick(velocity: velocity) else {
                            handlePestTap(fragID: frag.id, index: index)
                            return
                        }
                        flyingPest = FlyingPest(fragID: frag.id, pestIndex: index, start: .zero, velocity: velocity)
                        let flight = Physics.despawnTime(
                            from: .zero,
                            velocity: velocity,
                            viewport: CGRect(origin: .zero, size: CGSize(width: 2000, height: 1000))
                        ) ?? 0.6
                        withAnimation(.easeIn(duration: min(flight, 0.8))) {
                            flyingPest = FlyingPest(fragID: frag.id, pestIndex: index, start: .zero, velocity: velocity)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + min(flight, 0.8)) {
                            _ = viewModel.flickPest("DrupellaSnail", velocity: velocity, on: frag.id)
                            flyingPest = nil
                            viewModel.dismissPestTooltip()
                        }
                    }
            )
    }

    private func handlePestTap(fragID: UUID, index: Int) {
        let key = "\(fragID)-\(index)"
        guard !smushedPestIDs.contains(key) else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            _ = smushedPestIDs.insert(key)
        }
        viewModel.dismissPestTooltip()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            _ = viewModel.smushPest("DrupellaSnail", on: fragID)
            smushedPestIDs.remove(key)
        }
    }

    private func flyOffset(for pest: FlyingPest?) -> CGSize {
        guard let pest else { return .zero }
        let magnitude = max((pest.velocity.x * pest.velocity.x + pest.velocity.y * pest.velocity.y).squareRoot(), 1)
        return CGSize(width: pest.velocity.x / magnitude * 900, height: pest.velocity.y / magnitude * 900)
    }
}

/// Off-screen spawned snail crawling along the seabed toward its target coral (DEC-034).
struct CrawlingSnailView: View {
    @Bindable var viewModel: SandboxViewModel
    let snail: CrawlingSnail
    let seabedY: Double
    let seabedOffset: Double
    @State private var flickOffset = CGSize.zero

    var body: some View {
        let snailX = snail.currentX + seabedOffset
        let snailY = seabedY - snail.targetY - 14

        Image("Snail")
            .resizable()
            .scaledToFit()
            .frame(width: 36, height: 36)
            .scaleEffect(x: snail.isMovingLeft ? -1 : 1, y: 1)
            .frame(width: 52, height: 52)
            .contentShape(Rectangle())
            .position(x: snailX, y: snailY)
            .offset(flickOffset)
            .shadow(color: .black.opacity(0.4), radius: 4)
            .highPriorityGesture(
                TapGesture()
                    .onEnded {
                        viewModel.removeCrawlingSnail(id: snail.id)
                    }
            )
            .highPriorityGesture(
                DragGesture(minimumDistance: 4)
                    .onEnded { value in
                        let velocity = CGPoint(x: value.velocity.width, y: value.velocity.height)
                        guard Physics.isFlick(velocity: velocity) else { return }
                        let magnitude = max((velocity.x * velocity.x + velocity.y * velocity.y).squareRoot(), 1)
                        withAnimation(.easeOut(duration: 0.35)) {
                            flickOffset = CGSize(width: velocity.x / magnitude * 700, height: velocity.y / magnitude * 700)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            viewModel.flickCrawlingSnail(id: snail.id, velocity: velocity)
                        }
                    }
            )
    }
}
