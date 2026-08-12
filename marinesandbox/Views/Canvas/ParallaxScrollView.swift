import SwiftUI

// MARK: - Block Variants

public enum BlockVariant: CaseIterable {
    case blockA, blockB, blockC
}

// MARK: - Parallax Scroll View Container

public struct ParallaxScrollView: View {
    @State private var scrollX: CGFloat = 0.0
    @State private var dragOffset: CGFloat = 0.0 // State variable supporting momentum glide
    
    // Width scales dynamically: 1.5x screen width for iPhone 17 (19.5:9 display) scaling
    public let blockWidth = UIScreen.main.bounds.width * 1.5
    
    // Deterministic random seeds per layer to generate unique block patterns
    private let bgSeed = 1001
    private let midSeed = 2002
    private let fgSeed = 3003
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geometry in
            let viewportWidth = geometry.size.width
            let height = geometry.size.height
            
            // Total accumulated horizontal offset (incorporates active drag translation)
            let currentOffset = scrollX + dragOffset
            
            ZStack(alignment: .leading) {
                // 1. Background Layer (Parallax Ratio: 0.20)
                layerContainer(
                    viewportWidth: viewportWidth,
                    height: height,
                    offset: currentOffset * 0.20,
                    seed: bgSeed,
                    layerName: "Background"
                )
                
                // 2. Midground Layer (Parallax Ratio: 0.50)
                layerContainer(
                    viewportWidth: viewportWidth,
                    height: height,
                    offset: currentOffset * 0.50,
                    seed: midSeed,
                    layerName: "Midground"
                )
                
                // 3. Foreground Layer (Parallax Ratio: 1.0)
                layerContainer(
                    viewportWidth: viewportWidth,
                    height: height,
                    offset: currentOffset * 1.0,
                    seed: fgSeed,
                    layerName: "Foreground"
                )
            }
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
        offset: CGFloat,
        seed: Int,
        layerName: String
    ) -> some View {
        let startCol = Int(floor(-offset / blockWidth))
        let visibleCount = Int(ceil(viewportWidth / blockWidth)) + 1
        
        ZStack(alignment: .leading) {
            ForEach(startCol...(startCol + visibleCount), id: \.self) { col in
                let xPosition = CGFloat(col) * blockWidth + offset
                let variantIndex = getDeterministicVariant(col: col, seed: seed)
                let variant: BlockVariant = variantIndex == 0 ? .blockA : (variantIndex == 1 ? .blockB : .blockC)
                
                renderBlockView(layer: layerName, variant: variant, colIndex: col)
                    .frame(width: blockWidth, height: height)
                    .offset(x: xPosition)
            }
        }
    }
    
    private func getDeterministicVariant(col: Int, seed: Int) -> Int {
        let x = col ^ seed
        let hash = (x &* 324159265) ^ (x >> 16)
        return abs(hash) % 3
    }
    
    @ViewBuilder
    private func renderBlockView(layer: String, variant: BlockVariant, colIndex: Int) -> some View {
        let assetName: String
        switch layer {
        case "Background":
            switch variant {
            case .blockA: assetName = "BG/BG0"
            case .blockB: assetName = "BG/BG1"
            case .blockC: assetName = "BG/BG2"
            }
        case "Midground":
            switch variant {
            case .blockA: assetName = "MG/MG0"
            case .blockB: assetName = "MG/MG1"
            case .blockC: assetName = "MG/MG2"
            }
        case "Foreground":
            switch variant {
            case .blockA: assetName = "FG/FG0"
            case .blockB: assetName = "FG/FG1"
            case .blockC: assetName = "FG/FG2"
            }
        default:
            assetName = ""
        }
        
        Image(assetName)
            .resizable()
    }
}

// MARK: - PREVIEW

#Preview {
    ParallaxScrollView()
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
}
