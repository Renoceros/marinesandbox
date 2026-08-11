import SwiftUI

// MARK: - Block Variants

public enum BlockVariant: CaseIterable {
    case blockA, blockB, blockC
}

// MARK: - Parallax Scroll View Container

public struct ParallaxScrollView: View {
    @State private var scrollX: CGFloat = 0.0
    @State private var dragOffset: CGFloat = 0.0 // Supports animated momentum release
    
    // Width of each horizontal section
    public let blockWidth: CGFloat = 750.0
    
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
                // 1. Tropical Sunlit Background (Parallax Ratio: 0.20)
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
                
                // 3. Sandy Foreground Bed (Parallax Ratio: 1.0)
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
        switch layer {
        case "Background":
            switch variant {
            case .blockA: BackgroundViewA()
            case .blockB: BackgroundViewB()
            case .blockC: BackgroundViewC()
            }
        case "Midground":
            switch variant {
            case .blockA: MidgroundViewA(colIndex: colIndex)
            case .blockB: MidgroundViewB(colIndex: colIndex)
            case .blockC: MidgroundViewC(colIndex: colIndex)
            }
        case "Foreground":
            switch variant {
            case .blockA: ForegroundViewA()
            case .blockB: ForegroundViewB()
            case .blockC: ForegroundViewC()
            }
        default:
            Color.clear
        }
    }
}

// MARK: - BACKGROUND BLOCKS (Bright Warm Tropical Ocean / Sun Rays)

struct BackgroundViewA: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.35, green: 0.78, blue: 0.88), // Sunny Cyan
                    Color(red: 0.18, green: 0.60, blue: 0.72)  // Tropical Turquoise
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Warm shimmering sun rays
            LightRayShape()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.yellow.opacity(0.12), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 320, height: 600)
                .rotationEffect(Angle.degrees(-12))
                .offset(x: -80, y: -120)
        }
    }
}

struct BackgroundViewB: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.30, green: 0.75, blue: 0.85),
                    Color(red: 0.15, green: 0.55, blue: 0.68)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Subtle distant reef silhouettes
            Path { path in
                path.move(to: CGPoint(x: 0, y: 560))
                path.addQuadCurve(to: CGPoint(x: 380, y: 500), control: CGPoint(x: 200, y: 575))
                path.addQuadCurve(to: CGPoint(x: 750, y: 590), control: CGPoint(x: 580, y: 450))
                path.addLine(to: CGPoint(x: 750, y: 800))
                path.addLine(to: CGPoint(x: 0, y: 800))
                path.closeSubpath()
            }
            .fill(Color(red: 0.10, green: 0.48, blue: 0.60).opacity(0.3))
        }
    }
}

struct BackgroundViewC: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.35, green: 0.78, blue: 0.88),
                    Color(red: 0.20, green: 0.62, blue: 0.75)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Multiple shimmering sunbeams
            LightRayShape()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.yellow.opacity(0.08), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 250, height: 600)
                .rotationEffect(Angle.degrees(8))
                .offset(x: 180, y: -80)
        }
    }
}

// MARK: - MIDGROUND BLOCKS (Fauna & Golden Bubbles)

struct MidgroundViewA: View {
    let colIndex: Int
    @State private var animateBubbles = false
    
    var body: some View {
        ZStack {
            // Midground sandy bar silhouette
            Path { path in
                path.move(to: CGPoint(x: 0, y: 640))
                path.addCurve(to: CGPoint(x: 750, y: 620),
                              control1: CGPoint(x: 250, y: 540),
                              control2: CGPoint(x: 500, y: 700))
                path.addLine(to: CGPoint(x: 750, y: 800))
                path.addLine(to: CGPoint(x: 0, y: 800))
                path.closeSubpath()
            }
            .fill(Color(red: 0.12, green: 0.48, blue: 0.62).opacity(0.35))
            
            // Golden bubbles rising (representing sun reflections)
            ForEach(0..<6) { index in
                Circle()
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1.5)
                    .frame(width: CGFloat((index * 2) + 6), height: CGFloat((index * 2) + 6))
                    .offset(
                        x: CGFloat(120 + (index * 95)),
                        y: animateBubbles ? -200 : 700
                    )
                    .animation(
                        Animation.linear(duration: Double(6 + index))
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.3),
                        value: animateBubbles
                    )
            }
        }
        .onAppear {
            animateBubbles = true
        }
    }
}

struct MidgroundViewB: View {
    let colIndex: Int
    @State private var swimOffset = CGFloat.zero
    
    var body: some View {
        ZStack {
            // School of tropical fish silhouettes
            ForEach(0..<4) { idx in
                FishSilhouette()
                    .fill(Color(red: 0.08, green: 0.40, blue: 0.52).opacity(0.5))
                    .frame(width: 28, height: 14)
                    .offset(
                        x: (swimOffset + CGFloat(idx * 35)) - 100,
                        y: CGFloat(240 + (idx * 45) + (colIndex % 3 * 25))
                    )
            }
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 14.0).repeatForever(autoreverses: false)) {
                swimOffset = 850
            }
        }
    }
}

struct MidgroundViewC: View {
    let colIndex: Int
    @State private var animateBubbles = false
    
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 660))
                path.addQuadCurve(to: CGPoint(x: 750, y: 670), control: CGPoint(x: 375, y: 610))
                path.addLine(to: CGPoint(x: 750, y: 800))
                path.addLine(to: CGPoint(x: 0, y: 800))
                path.closeSubpath()
            }
            .fill(Color(red: 0.12, green: 0.48, blue: 0.62).opacity(0.40))
            
            // Soft floating sun speckles
            Circle()
                .fill(RadialGradient(
                    colors: [Color.yellow.opacity(0.18), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 70
                ))
                .frame(width: 140, height: 140)
                .offset(x: 320, y: animateBubbles ? 120 : 480)
                .animation(
                    Animation.easeInOut(duration: 9.0)
                        .repeatForever(autoreverses: true),
                    value: animateBubbles
                )
        }
        .onAppear {
            animateBubbles = true
        }
    }
}

// MARK: - FOREGROUND BLOCKS (Warm Peach / Golden Sand Dunes)

struct ForegroundViewA: View {
    var body: some View {
        ZStack {
            // Main sandy floor - Warm Coral Sand
            Path { path in
                path.move(to: CGPoint(x: 0, y: 620))
                path.addCurve(to: CGPoint(x: 750, y: 645),
                              control1: CGPoint(x: 200, y: 580),
                              control2: CGPoint(x: 500, y: 690))
                path.addLine(to: CGPoint(x: 750, y: 800))
                path.addLine(to: CGPoint(x: 0, y: 800))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.94, green: 0.82, blue: 0.68), // Peach Sand
                        Color(red: 0.78, green: 0.64, blue: 0.50)  // Golden Sand shadow
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Foreground rocky coral mound
            Path { path in
                path.move(to: CGPoint(x: 520, y: 670))
                path.addQuadCurve(to: CGPoint(x: 630, y: 590), control: CGPoint(x: 550, y: 585))
                path.addQuadCurve(to: CGPoint(x: 710, y: 655), control: CGPoint(x: 680, y: 605))
                path.addLine(to: CGPoint(x: 710, y: 800))
                path.addLine(to: CGPoint(x: 520, y: 800))
                path.closeSubpath()
            }
            .fill(Color(red: 0.58, green: 0.46, blue: 0.35)) // Warm Sandstone
        }
    }
}

struct ForegroundViewB: View {
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 645))
                path.addCurve(to: CGPoint(x: 750, y: 605),
                              control1: CGPoint(x: 250, y: 690),
                              control2: CGPoint(x: 500, y: 555))
                path.addLine(to: CGPoint(x: 750, y: 800))
                path.addLine(to: CGPoint(x: 0, y: 800))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.92, green: 0.80, blue: 0.66),
                        Color(red: 0.75, green: 0.62, blue: 0.48)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

struct ForegroundViewC: View {
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 605))
                path.addCurve(to: CGPoint(x: 750, y: 625),
                              control1: CGPoint(x: 300, y: 555),
                              control2: CGPoint(x: 450, y: 675))
                path.addLine(to: CGPoint(x: 750, y: 800))
                path.addLine(to: CGPoint(x: 0, y: 800))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.94, green: 0.82, blue: 0.68),
                        Color(red: 0.78, green: 0.64, blue: 0.50)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Left rocky protrusion
            Path { path in
                path.move(to: CGPoint(x: 0, y: 605))
                path.addQuadCurve(to: CGPoint(x: 130, y: 545), control: CGPoint(x: 60, y: 555))
                path.addQuadCurve(to: CGPoint(x: 210, y: 645), control: CGPoint(x: 180, y: 595))
                path.addLine(to: CGPoint(x: 210, y: 800))
                path.addLine(to: CGPoint(x: 0, y: 800))
                path.closeSubpath()
            }
            .fill(Color(red: 0.60, green: 0.48, blue: 0.36))
        }
    }
}

// MARK: - DRAWING SHAPE HELPERS

struct LightRayShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.3, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.7, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct FishSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.5))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.7, y: 0), control: CGPoint(x: rect.width * 0.3, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.width, y: rect.height * 0.3), control: CGPoint(x: rect.width * 0.85, y: rect.height * 0.15))
        path.addLine(to: CGPoint(x: rect.width * 0.9, y: rect.height * 0.5))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.7))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.7, y: rect.height), control: CGPoint(x: rect.width * 0.85, y: rect.height * 0.85))
        path.addQuadCurve(to: CGPoint(x: 0, y: rect.height * 0.5), control: CGPoint(x: rect.width * 0.3, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - PREVIEW

#Preview {
    ParallaxScrollView()
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
}
