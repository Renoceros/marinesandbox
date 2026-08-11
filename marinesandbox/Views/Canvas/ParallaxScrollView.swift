import SwiftUI

// MARK: - Block Variants

public enum BlockVariant: CaseIterable {
    case blockA, blockB, blockC
}

// MARK: - Parallax Scroll View Container

public struct ParallaxScrollView: View {
    @State private var scrollX: CGFloat = 0.0
    @GestureState private var dragOffset: CGFloat = 0.0
    
    // Width of each procedurally tiled horizontal block
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
                // 1. Deep Ocean Background (Parallax Ratio: 0.15)
                // Moves slowly, creating the illusion of deep distance.
                layerContainer(
                    viewportWidth: viewportWidth,
                    height: height,
                    offset: currentOffset * 0.15,
                    seed: bgSeed,
                    layerName: "Background"
                )
                
                // 2. Midground Layer (Parallax Ratio: 0.45)
                // Hosts floating particles, rising bubbles, and fish silhouettes.
                layerContainer(
                    viewportWidth: viewportWidth,
                    height: height,
                    offset: currentOffset * 0.45,
                    seed: midSeed,
                    layerName: "Midground"
                )
                
                // 3. Seabed Foreground (Parallax Ratio: 1.0)
                // The interactive interactive layer where corals grow.
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
                    .updating($dragOffset) { value, state, _ in
                        // Swipe left (negative translation) translates offset negatively,
                        // shifting the viewport to the right (natural scrolling).
                        state = value.translation.width
                    }
                    .onEnded { value in
                        scrollX += value.translation.width
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
        // Find which column indices intersect the current viewport range
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
    
    // Linear congruential generator logic to map columns to deterministic block types
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

// MARK: - BACKGROUND BLOCKS (Deep Blue / Rays / Trenches)

struct BackgroundViewA: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.02, green: 0.05, blue: 0.20),
                    Color(red: 0.05, green: 0.12, blue: 0.32)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            // Floating background light beams
            LightRayShape()
                .fill(Color.white.opacity(0.04))
                .frame(width: 300, height: 600)
                .rotationEffect(.degrees(-15))
                .offset(x: -100, y: -100)
        }
    }
}

struct BackgroundViewB: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.01, green: 0.04, blue: 0.18),
                    Color(red: 0.04, green: 0.10, blue: 0.28)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            // Silhouetted deep ocean trench shape
            Path { path in
                path.move(to: CGPoint(x: 0, y: 550))
                path.addQuadCurve(to: CGPoint(x: 350, y: 480), control: CGPoint(x: 180, y: 560))
                path.addQuadCurve(to: CGPoint(x: 750, y: 580), control: CGPoint(x: 550, y: 420))
                path.addLine(to: CGPoint(x: 750, y: 800))
                path.addLine(to: CGPoint(x: 0, y: 800))
                path.closeSubpath()
            }
            .fill(Color(red: 0.01, green: 0.03, blue: 0.14).opacity(0.5))
        }
    }
}

struct BackgroundViewC: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.02, green: 0.05, blue: 0.20),
                    Color(red: 0.05, green: 0.15, blue: 0.35)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            // Scattered beams
            LightRayShape()
                .fill(Color.white.opacity(0.03))
                .frame(width: 250, height: 600)
                .rotationEffect(.degrees(10))
                .offset(x: 150, y: -80)
        }
    }
}

// MARK: - MIDGROUND BLOCKS (Floating Bubbles & Silhouetted Fauna)

struct MidgroundViewA: View {
    let colIndex: Int
    @State private var animateBubbles = false
    
    var body: some View {
        ZStack {
            // Silhouette of a distant reef hill
            Path { path in
                path.move(to: CGPoint(x: 0, y: 650))
                path.addCurve(to: CGPoint(x: 750, y: 630),
                              control1: CGPoint(x: 250, y: 520),
                              control2: CGPoint(x: 500, y: 720))
                path.addLine(to: CGPoint(x: 750, y: 800))
                path.addLine(to: CGPoint(x: 0, y: 800))
                path.closeSubpath()
            }
            .fill(Color(red: 0.02, green: 0.06, blue: 0.22).opacity(0.4))
            
            // Rising micro-bubbles (Animated)
            ForEach(0..<6) { index in
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    .frame(width: CGFloat((index * 2) + 4), height: CGFloat((index * 2) + 4))
                    .offset(
                        x: CGFloat(100 + (index * 90)),
                        y: animateBubbles ? -200 : 700
                    )
                    .animation(
                        Animation.linear(duration: Double(5 + index))
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.4),
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
            // Schooling fish silhouettes swimming horizontally
            ForEach(0..<4) { idx in
                FishSilhouette()
                    .fill(Color(red: 0.03, green: 0.10, blue: 0.30).opacity(0.6))
                    .frame(width: 25, height: 12)
                    .offset(
                        x: (swimOffset + CGFloat(idx * 40)) - 100,
                        y: CGFloat(200 + (idx * 50) + (colIndex % 3 * 30))
                    )
            }
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 12.0).repeatForever(autoreverses: false)) {
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
            // Subtle structures
            Path { path in
                path.move(to: CGPoint(x: 0, y: 680))
                path.addQuadCurve(to: CGPoint(x: 750, y: 690), control: CGPoint(x: 375, y: 620))
                path.addLine(to: CGPoint(x: 750, y: 800))
                path.addLine(to: CGPoint(x: 0, y: 800))
                path.closeSubpath()
            }
            .fill(Color(red: 0.02, green: 0.06, blue: 0.22).opacity(0.45))
            
            // Single large floating particle plume
            Circle()
                .fill(RadialGradient(
                    colors: [Color.white.opacity(0.15), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 80
                ))
                .frame(width: 160, height: 160)
                .offset(x: 350, y: animateBubbles ? 100 : 500)
                .animation(
                    Animation.easeInOut(duration: 8.0)
                        .repeatForever(autoreverses: true),
                    value: animateBubbles
                )
        }
        .onAppear {
            animateBubbles = true
        }
    }
}

// MARK: - FOREGROUND BLOCKS (Sandy Hills & Rocks)

struct ForegroundViewA: View {
    var body: some View {
        ZStack {
            // Main sandy floor
            Path { path in
                path.move(to: CGPoint(x: 0, y: 620))
                path.addCurve(to: CGPoint(x: 750, y: 650),
                              control1: CGPoint(x: 200, y: 570),
                              control2: CGPoint(x: 500, y: 700))
                path.addLine(to: CGPoint(x: 750, y: 800))
                path.addLine(to: CGPoint(x: 0, y: 800))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.08, green: 0.18, blue: 0.32),
                        Color(red: 0.02, green: 0.06, blue: 0.14)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Detailed foreground rock silhouette
            Path { path in
                path.move(to: CGPoint(x: 500, y: 680))
                path.addQuadCurve(to: CGPoint(x: 620, y: 600), control: CGPoint(x: 530, y: 590))
                path.addQuadCurve(to: CGPoint(x: 700, y: 660), control: CGPoint(x: 670, y: 610))
                path.addLine(to: CGPoint(x: 700, y: 800))
                path.addLine(to: CGPoint(x: 500, y: 800))
                path.closeSubpath()
            }
            .fill(Color(red: 0.03, green: 0.09, blue: 0.20))
        }
    }
}

struct ForegroundViewB: View {
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 650))
                path.addCurve(to: CGPoint(x: 750, y: 610),
                              control1: CGPoint(x: 250, y: 700),
                              control2: CGPoint(x: 500, y: 550))
                path.addLine(to: CGPoint(x: 750, y: 800))
                path.addLine(to: CGPoint(x: 0, y: 800))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.09, green: 0.20, blue: 0.35),
                        Color(red: 0.02, green: 0.07, blue: 0.16)
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
                path.move(to: CGPoint(x: 0, y: 610))
                path.addCurve(to: CGPoint(x: 750, y: 630),
                              control1: CGPoint(x: 300, y: 560),
                              control2: CGPoint(x: 450, y: 680))
                path.addLine(to: CGPoint(x: 750, y: 800))
                path.addLine(to: CGPoint(x: 0, y: 800))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.08, green: 0.18, blue: 0.32),
                        Color(red: 0.02, green: 0.06, blue: 0.14)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Left rocky outcrop
            Path { path in
                path.move(to: CGPoint(x: 0, y: 610))
                path.addQuadCurve(to: CGPoint(x: 120, y: 550), control: CGPoint(x: 50, y: 560))
                path.addQuadCurve(to: CGPoint(x: 200, y: 650), control: CGPoint(x: 170, y: 600))
                path.addLine(to: CGPoint(x: 200, y: 800))
                path.addLine(to: CGPoint(x: 0, y: 800))
                path.closeSubpath()
            }
            .fill(Color(red: 0.03, green: 0.08, blue: 0.18))
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
        // Draw a simple sleek fish body
        path.move(to: CGPoint(x: 0, y: rect.height * 0.5))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.7, y: 0), control: CGPoint(x: rect.width * 0.3, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.width, y: rect.height * 0.3), control: CGPoint(x: rect.width * 0.85, y: rect.height * 0.15))
        // Tail Fin
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
