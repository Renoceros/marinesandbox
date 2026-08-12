import SwiftUI

// MARK: - Parallax Scroll View

public struct ParallaxScrollView: View {
    @State private var scrollX: CGFloat = 0.0
    @State private var dragOffset: CGFloat = 0.0 // Follows active user finger drag
    
    // Deterministic random seeds per layer as defined in TDD Section 4.1
    private let bgSeed = 42
    private let midSeed = 101
    private let fgSeed = 2023
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geometry in
            let viewportWidth = geometry.size.width
            let height = geometry.size.height
            
            // Width scales dynamically: 1.5x screen width of the container (avoids deprecated UIScreen.main in iOS 26+)
            let blockWidth = viewportWidth * 1.5
            
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
                    seed: midSeed,
                    layerName: "Midground",
                    alignment: .top
                )
                
                // 3rd Layer: Background Layer (Parallax Ratio: 0.20, Top-Aligned)
                layerContainer(
                    viewportWidth: viewportWidth,
                    height: height,
                    blockWidth: blockWidth,
                    offset: currentOffset * 0.20,
                    seed: bgSeed,
                    layerName: "Background",
                    alignment: .top
                )
                
                // 4th Layer (Frontmost): Foreground Layer (Parallax Ratio: 1.00, Bottom-Aligned)
                layerContainer(
                    viewportWidth: viewportWidth,
                    height: height,
                    blockWidth: blockWidth,
                    offset: currentOffset * 1.00,
                    seed: fgSeed,
                    layerName: "Foreground",
                    alignment: .bottom
                )
            }
            .edgesIgnoringSafeArea(.all)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        // Calculate inertia using predictedEndTranslation to provide a fluid, gliding feel
                        let predicted = value.predictedEndTranslation.width
                        
                        withAnimation(.easeOut(duration: 1.2)) {
                            scrollX += predicted
                            dragOffset = 0.0
                        }
                    }
            )
        }
    }
    
    // Renders the horizontal window of visible columns for a layer on the fly
    @ViewBuilder
    private func layerContainer(
        viewportWidth: CGFloat,
        height: CGFloat,
        blockWidth: CGFloat,
        offset: CGFloat,
        seed: Int,
        layerName: String,
        alignment: Alignment
    ) -> some View {
        // Find the base column index currently aligned near the left edge of the screen
        let startCol = Int(floor(-offset / blockWidth))
        
        // Calculate the columns to render (including a safety margin on left and right)
        let columns = Array(startCol - 1...startCol + 2)
        
        // Loop over the specific column numbers. Keying by their actual coordinate (id: \.self)
        // ensures that views representing physical coordinates slide naturally without changing assets
        // or triggering implicit crossfades when scroll offsets shift startCol.
        ZStack(alignment: .leading) {
            ForEach(columns, id: \.self) { col in
                let xPosition = CGFloat(col) * blockWidth + offset
                let variantIndex = getDeterministicVariant(col: col, seed: seed)
                
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
                .transition(.identity) // Disable implicit entry/exit animation fades inside withAnimation blocks
            }
        }
    }
    
    // Deterministic variant calculation matching TDD formula
    private func getDeterministicVariant(col: Int, seed: Int) -> Int {
        let x = col ^ seed
        let hash = (x &* 324159265) ^ (x >> 16)
        return abs(hash) % 3
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
