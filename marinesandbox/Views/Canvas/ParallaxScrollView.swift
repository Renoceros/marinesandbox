import SwiftUI

// MARK: - Parallax Scroll View

public struct ParallaxScrollView: View {
    @Binding var scrollX: CGFloat

    // `scrollX` as it stood when the current drag began, or nil between drags.
    //
    // The live finger delta used to be a private `dragOffset` that only folded
    // back into `scrollX` on release. That kept the parallax layers smooth but
    // froze every *other* reader of `scrollX` — the corals above all — until the
    // gesture ended, at which point they jumped. `scrollX` is written on every
    // `onChanged` so all of them track the finger frame-by-frame.
    //
    // `DragGesture.translation` is cumulative from the gesture's start, so adding
    // it to a `scrollX` we are ourselves mutating each frame would compound it.
    // Anchoring to the start value keeps the arithmetic stable.
    @State private var dragStartX: CGFloat?
    
    public init(scrollX: Binding<CGFloat>) {
        self._scrollX = scrollX
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let viewportWidth = geometry.size.width
            let height = geometry.size.height

            // Shared drag range every layer's offset is scaled from (spec: scrollX in [-3.5*viewportWidth, 0])
            let panRange = ParallaxMetrics.panRange(viewportWidth: viewportWidth)
            let minScroll = -panRange

            // Total accumulated horizontal offset. `scrollX` is live during a drag,
            // so this is the single value every layer and entity scales from.
            let currentOffset = scrollX

            ZStack(alignment: .leading) {
                // 1st Layer (Backmost): Linear gradient backdrop ignoring safe area
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "042638"), location: 0.0),
                        .init(color: Color(hex: "3BAFED"), location: 0.55),
                        .init(color: Color(hex: "3BAFED"), location: 1.0)
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .edgesIgnoringSafeArea(.all)

                // 2nd Layer: Midground Layer (Parallax Ratio: 0.50, Top-Aligned)
                layerContainer(
                    viewportWidth: viewportWidth,
                    height: height,
                    ratio: 0.50,
                    panRange: panRange,
                    currentOffset: currentOffset,
                    layerName: "Midground",
                    alignment: .top,
                    widthScale: 1.5,
                    verticalOffset: 0,
                    opacity: 0.5
                    
                )

                // 3rd Layer: Background Layer (Parallax Ratio: 0.20, Top-Aligned)
                layerContainer(
                    viewportWidth: viewportWidth,
                    height: height,
                    ratio: 0.20,
                    panRange: panRange,
                    currentOffset: currentOffset,
                    layerName: "Background",
                    alignment: .top,
                    widthScale: 1.5,
                    verticalOffset: 0,
                    opacity: 0.8
                )

                // 4th Layer: Foreground Layer — the seabed. Corals are planted *in*
                // this layer, so its ratio lives in `ParallaxMetrics` where the
                // entity layer reads the same value. Hardcoding a ratio here is
                // what let the sand slide out from under the reef.
                layerContainer(
                    viewportWidth: viewportWidth,
                    height: height,
                    ratio: ParallaxMetrics.seabedRatio,
                    panRange: panRange,
                    currentOffset: currentOffset,
                    layerName: "Foreground",
                    alignment: .bottom,
                    widthScale: ParallaxMetrics.seabedWidthScale,
                    verticalOffset: 0
                )

                // 5th Layer (Frontmost): Topground Layer (Parallax Ratio: 0.10, Top-Aligned)
                layerContainer(
                    viewportWidth: viewportWidth,
                    height: height,
                    ratio: 1.00,
                    panRange: panRange,
                    currentOffset: currentOffset,
                    layerName: "Topground",
                    alignment: .top,
                    widthScale: 1.5,
                    verticalOffset: 0,
                    opacity: 0.9
                )
            }
            .edgesIgnoringSafeArea(.all)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let anchor: CGFloat
                        if let dragStartX {
                            anchor = dragStartX
                        } else {
                            anchor = scrollX
                            dragStartX = anchor
                        }

                        // Past either edge, resist with rubber-banding instead of a hard stop
                        let rawOffset = anchor + value.translation.width
                        let maxStretch = viewportWidth * 0.28
                        let resolvedOffset: CGFloat
                        if rawOffset > 0 {
                            resolvedOffset = rubberBand(rawOffset, dimension: maxStretch)
                        } else if rawOffset < minScroll {
                            resolvedOffset = minScroll - rubberBand(minScroll - rawOffset, dimension: maxStretch)
                        } else {
                            resolvedOffset = rawOffset
                        }
                        // Written every frame, not just on release, so the corals
                        // stay glued to the world while the finger is still down.
                        scrollX = resolvedOffset
                    }
                    .onEnded { value in
                        // Inertia is projected from where the drag began, matching the
                        // anchor `onChanged` used — `scrollX` has moved since then.
                        let anchor = dragStartX ?? scrollX
                        dragStartX = nil

                        // Calculate inertia using predictedEndTranslation
                        let predicted = value.predictedEndTranslation.width
                        let targetX = anchor + predicted
                        let clampedTarget = max(minScroll, min(0, targetX))

                        // Only the edges have anything to rubber-band against, so only
                        // an out-of-bounds target gets the elastic overshoot spring.
                        // An in-bounds settle uses a critically-damped spring so it
                        // glides to a stop instead of bouncing mid-scroll.
                        let isOutOfBounds = targetX < minScroll || targetX > 0
                        let settleSpring: Animation = isOutOfBounds
                            ? .spring(response: 0.45, dampingFraction: 0.55)
                            : .spring(response: 0.35, dampingFraction: 0.9)

                        withAnimation(settleSpring) {
                            scrollX = clampedTarget
                        }
                    }
            )
        }
    }
    
    // Classic iOS overscroll resistance curve: asymptotically approaches `dimension`
    // as `overscroll` grows, so the drag never stretches past the cap.
    private func rubberBand(_ overscroll: CGFloat, dimension: CGFloat, coefficient: CGFloat = 0.55) -> CGFloat {
        (1 - 1 / (overscroll * coefficient / dimension + 1)) * dimension
    }

    // Renders a horizontal strip of stitched columns (no infinite scroll).
    //
    // Every artwork is authored one screen wide, so `widthScale: 1.0` renders it
    // at exactly its intended width. Height is never set directly — it falls out
    // of the asset's own aspect ratio, which is what keeps the zoom uniform.
    // Driving size from a target *height* would work back to a different width
    // and squash the artwork horizontally; driving it from width cannot.
    //
    // To move a layer up or down, use `verticalOffset` rather than resizing it.
    //
    // Column count is derived rather than fixed: every layer shares the same
    // drag range, but a layer with ratio < 1 only travels `panRange * ratio` px
    // of it, so it needs just enough columns to keep the viewport covered
    // across its own (smaller) travel.
    @ViewBuilder
    private func layerContainer(
        viewportWidth: CGFloat,
        height: CGFloat,
        ratio: CGFloat,
        panRange: CGFloat,
        currentOffset: CGFloat,
        layerName: String,
        alignment: Alignment,
        widthScale: CGFloat = 1.0,
        verticalOffset: CGFloat = 0,
        opacity: Double = 1.0
    ) -> some View {
        let blockWidth = viewportWidth * widthScale
        let offset = currentOffset * ratio
        let columnCount = min(24, max(1, Int(ceil((viewportWidth + panRange * ratio) / blockWidth))))

        ZStack(alignment: .leading) {
            // Columns -1 and `columnCount` repeat the real edge columns one slot further
            // out. They sit outside the normal [minScroll, 0] pan range and only ever peek
            // into view during rubber-band overscroll, so it reads as "there's more land
            // here" instead of the bare backdrop color.
            ForEach(-1...columnCount, id: \.self) { col in
                let xPosition = CGFloat(col) * blockWidth + offset
                let permCol = max(0, min(columnCount - 1, col))
                let perm = getPermutation(col: permCol)

                // Assign a unique variant index from the permutation list based on the layer.
                // Topground shares Background's slot: they draw from different asset sets,
                // so a matching index never reads as a repeat.
                let variantIndex = perm[variantSlot(for: layerName)]

                VStack(spacing: 0) {
                    if alignment == .bottom {
                        Spacer()
                    }

                    renderBlockView(layer: layerName, variantIndex: variantIndex)
                        .frame(width: blockWidth)

                    if alignment == .top {
                        Spacer()
                    }
                }
                .frame(width: blockWidth, height: height)
                .offset(x: xPosition, y: verticalOffset)
                .opacity(opacity)
                .transition(.identity) // Disable implicit SwiftUI transition fades
            }
        }
    }
    
    // Returns a unique permutation of variant indices [0, 1, 2] per column
    // Shared with the planting logic via `ParallaxMetrics`, so the renderer and
    // the coral that lands on it can never disagree about which sand is where.
    private func getPermutation(col: Int) -> [Int] {
        ParallaxMetrics.permutation(col: col)
    }
    
    private func variantSlot(for layerName: String) -> Int {
        switch layerName {
        case "Background", "Topground": return 0
        case "Midground": return 1
        default: return 2
        }
    }

    private func assetPrefix(for layerName: String) -> String {
        switch layerName {
        case "Topground": return "SF"
        case "Background": return "BG"
        case "Midground": return "MG"
        default: return "FG"
        }
    }

    // Helper to render Image assets directly by name mapping
    @ViewBuilder
    private func renderBlockView(layer: String, variantIndex: Int) -> some View {
        Image("\(assetPrefix(for: layer))\(variantIndex)")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

// MARK: - COLOR HEX EXTENSION

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - PREVIEW

#Preview {
    ParallaxScrollViewPreviewHost()
}

// `.constant(0)` would silently discard every drag-release write to `scrollX`,
// making the canvas preview snap back to the start on every release. A tiny
// @State-backed host gives the preview a real, mutable binding to work with.
private struct ParallaxScrollViewPreviewHost: View {
    @State private var scrollX: CGFloat = 0.0

    var body: some View {
        ParallaxScrollView(scrollX: $scrollX)
            .background(Color.black)
            .edgesIgnoringSafeArea(.all)
    }
}
