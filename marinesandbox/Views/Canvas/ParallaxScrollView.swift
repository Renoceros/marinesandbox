import SwiftUI

// MARK: - Parallax Scroll View

public struct ParallaxScrollView: View {
    @State private var scrollX: CGFloat = 0.0
    @State private var dragOffset: CGFloat = 0.0 // Follows active user finger drag
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geometry in
            let viewportWidth = geometry.size.width
            let height = geometry.size.height

            // Shared drag range every layer's offset is scaled from (spec: scrollX in [-3.5*viewportWidth, 0])
            let panRange = viewportWidth * 3.5
            let minScroll = -panRange

            // Total accumulated horizontal offset (incorporates active drag translation)
            let currentOffset = scrollX + dragOffset

            ZStack(alignment: .leading) {
                // 1st Layer (Backmost): Solid backdrop color (#3BAFED) ignoring safe area
                Color(hex: "3BAFED")
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
                    // verticalOffset: height * 0.12
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
                    // verticalOffset: height * 0.07
                )

                // 4th Layer (Frontmost): Foreground Layer (Parallax Ratio: 1.00, Bottom-Aligned)
                layerContainer(
                    viewportWidth: viewportWidth,
                    height: height,
                    ratio: 1.00,
                    panRange: panRange,
                    currentOffset: currentOffset,
                    layerName: "Foreground",
                    alignment: .bottom,
                    // verticalOffset: -height * 0.08
                )
            }
            .edgesIgnoringSafeArea(.all)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Past either edge, resist with rubber-banding instead of a hard stop
                        let rawOffset = scrollX + value.translation.width
                        let maxStretch = viewportWidth * 0.28
                        let resolvedOffset: CGFloat
                        if rawOffset > 0 {
                            resolvedOffset = rubberBand(rawOffset, dimension: maxStretch)
                        } else if rawOffset < minScroll {
                            resolvedOffset = minScroll - rubberBand(minScroll - rawOffset, dimension: maxStretch)
                        } else {
                            resolvedOffset = rawOffset
                        }
                        dragOffset = resolvedOffset - scrollX
                    }
                    .onEnded { value in
                        // Calculate inertia using predictedEndTranslation
                        let predicted = value.predictedEndTranslation.width
                        let targetX = scrollX + predicted
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
                            dragOffset = 0.0
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

    // Renders the horizontal window of exactly 3 stitched columns (no infinite scroll).
    //
    // Every layer shares the same drag range (`currentOffset` clamped to
    // [-panRange, 0]), but slower layers (ratio < 1) only ever move through
    // `panRange * ratio` px of that range. Sizing every layer's segments at a
    // fixed 1.5x viewport width (matching only the ratio-1.0 foreground) left
    // slower layers unable to ever pan their 3rd (and, for Background, 2nd)
    // segment into view. Scaling segment width by ratio makes each layer's 3
    // segments exactly span the viewport across its own (smaller) offset range.
    private func segmentWidth(viewportWidth: CGFloat, panRange: CGFloat, ratio: CGFloat) -> CGFloat {
        (viewportWidth + panRange * ratio) / 3
    }

    @ViewBuilder
    private func layerContainer(
        viewportWidth: CGFloat,
        height: CGFloat,
        ratio: CGFloat,
        panRange: CGFloat,
        currentOffset: CGFloat,
        layerName: String,
        alignment: Alignment,
        verticalOffset: CGFloat = 0
    ) -> some View {
        let blockWidth = segmentWidth(viewportWidth: viewportWidth, panRange: panRange, ratio: ratio)
        let offset = currentOffset * ratio
        ZStack(alignment: .leading) {
            // Columns -1 and 3 are the real 0/2 edge columns repeated one slot further out.
            // They sit outside the normal [minScroll, 0] pan range and only ever peek into
            // view during rubber-band overscroll, so it reads as "there's more land here"
            // instead of the bare backdrop color.
            ForEach(-1..<4, id: \.self) { col in
                let xPosition = CGFloat(col) * blockWidth + offset
                let permCol = max(0, min(2, col))
                let perm = getPermutation(col: permCol)

                // Assign a unique variant index from the permutation list based on the layer
                // Background -> perm[0], Midground -> perm[1], Foreground -> perm[2]
                let variantIndex = layerName == "Background" ? perm[0] : (layerName == "Midground" ? perm[1] : perm[2])
                
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
                .transition(.identity) // Disable implicit SwiftUI transition fades
            }
        }
    }
    
    // Returns a unique permutation of variant indices [0, 1, 2] per column
    private func getPermutation(col: Int) -> [Int] {
        let permutations = [
            [0, 1, 2], // Permutation 0
            [0, 2, 1], // Permutation 1
            [1, 0, 2], // Permutation 2
            [1, 2, 0], // Permutation 3
            [2, 0, 1], // Permutation 4
            [2, 1, 0]  // Permutation 5
        ]
        
        let hash = abs((col ^ 1001) &* 324159265) % 6
        return permutations[hash]
    }
    
    // Helper to render Image assets directly by name mapping
    @ViewBuilder
    private func renderBlockView(layer: String, variantIndex: Int) -> some View {
        let prefix = layer == "Background" ? "BG" : (layer == "Midground" ? "MG" : "FG")
        Image("\(prefix)\(variantIndex)")
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
    ParallaxScrollView()
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
}
