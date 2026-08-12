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
            
            // Width of each segment: 1.5x of the iPhone screen width
            let blockWidth = viewportWidth * 1.5
            
            // Total content width is 3 * blockWidth (4.5 * viewportWidth)
            // Left scroll boundary limits panning to exactly 3 stitched segments
            let minScroll = viewportWidth - (blockWidth * 3)
            
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
                    blockWidth: blockWidth,
                    offset: currentOffset * 0.50,
                    layerName: "Midground",
                    alignment: .top
                )
                
                // 3rd Layer: Background Layer (Parallax Ratio: 0.20, Top-Aligned)
                layerContainer(
                    viewportWidth: viewportWidth,
                    height: height,
                    blockWidth: blockWidth,
                    offset: currentOffset * 0.20,
                    layerName: "Background",
                    alignment: .top
                )
                
                // 4th Layer (Frontmost): Foreground Layer (Parallax Ratio: 1.00, Bottom-Aligned)
                layerContainer(
                    viewportWidth: viewportWidth,
                    height: height,
                    blockWidth: blockWidth,
                    offset: currentOffset * 1.00,
                    layerName: "Foreground",
                    alignment: .bottom
                )
            }
            .edgesIgnoringSafeArea(.all)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Strictly clamp active drag offsets to prevent swiping past limits
                        let activeOffset = scrollX + value.translation.width
                        let clampedOffset = max(minScroll, min(0, activeOffset))
                        dragOffset = clampedOffset - scrollX
                    }
                    .onEnded { value in
                        // Calculate inertia using predictedEndTranslation
                        let predicted = value.predictedEndTranslation.width
                        let targetX = scrollX + predicted
                        let clampedTarget = max(minScroll, min(0, targetX))
                        
                        withAnimation(.easeOut(duration: 1.2)) {
                            scrollX = clampedTarget
                            dragOffset = 0.0
                        }
                    }
            )
        }
    }
    
    // Renders the horizontal window of exactly 3 stitched columns (no infinite scroll)
    @ViewBuilder
    private func layerContainer(
        viewportWidth: CGFloat,
        height: CGFloat,
        blockWidth: CGFloat,
        offset: CGFloat,
        layerName: String,
        alignment: Alignment
    ) -> some View {
        ZStack(alignment: .leading) {
            ForEach(0..<3, id: \.self) { col in
                let xPosition = CGFloat(col) * blockWidth + offset
                let perm = getPermutation(col: col)
                
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
                .offset(x: xPosition)
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
