import SwiftUI

/// **SandboxToolOverlayView: Care Tools & Simulation Speed Bar (DEC-007, DEC-031, DEC-032)**
///
/// Anchors the Sponge Bubble Tool at top-leading and Simulation Speed Controls at top-trailing.
struct SandboxToolOverlayView: View {
    @Bindable var viewModel: SandboxViewModel
    let seabedY: Double
    @Binding var lastBrushPoint: CGPoint?

    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 10) {
                // Top-Leading: Sponge in a Bubble (DEC-032)
                SpongeBubbleView(
                    viewModel: viewModel,
                    seabedY: seabedY,
                    lastBrushPoint: $lastBrushPoint
                )

                Spacer()

                // Top-Trailing: Reset & Speed Controls
                HStack(spacing: 8) {
                    ResetColdOpenButton(viewModel: viewModel)
                    FastForwardButton(viewModel: viewModel)
                    DebugSpeedButton(viewModel: viewModel)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 56) // clear safe area status bar

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Translucent shimmering bubble encapsulating the Sponge tool.
struct SpongeBubbleView: View {
    @Bindable var viewModel: SandboxViewModel
    let seabedY: Double
    @Binding var lastBrushPoint: CGPoint?

    @State private var spongeOffset: CGSize = .zero
    @State private var isSpongeDragging: Bool = false
    @State private var isBubblePopped: Bool = false
    @State private var popScale: CGFloat = 1.0
    @State private var popOpacity: Double = 0.0

    var body: some View {
        ZStack {
            if !isBubblePopped {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.cyan.opacity(0.45),
                                Color.blue.opacity(0.2),
                                Color.white.opacity(0.6)
                            ],
                            center: .topLeading,
                            startRadius: 4,
                            endRadius: 36
                        )
                    )
                    .frame(width: 62, height: 62)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.9), .cyan.opacity(0.6), .white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .cyan.opacity(0.5), radius: 10)
                    .transition(.scale.combined(with: .opacity))
            } else if popOpacity > 0 {
                Circle()
                    .stroke(Color.white.opacity(popOpacity), lineWidth: 2)
                    .scaleEffect(popScale)
                    .frame(width: 62, height: 62)
            }

            Image("Sponge")
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .scaleEffect(isSpongeDragging ? 1.2 : 1.0)
                .shadow(color: isSpongeDragging ? .cyan.opacity(0.8) : .clear, radius: 12)
                .offset(spongeOffset)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isSpongeDragging {
                                isSpongeDragging = true
                                isBubblePopped = true
                                AudioPlayerService.shared.playSFX("pest_splash")
                                popScale = 1.0
                                popOpacity = 0.8
                                withAnimation(.easeOut(duration: 0.3)) {
                                    popScale = 1.6
                                    popOpacity = 0.0
                                }
                            }
                            spongeOffset = value.translation

                            let seabedOffset = ParallaxMetrics.seabedOffset(scrollX: viewModel.scrollX)
                            let touchLocation = CGPoint(x: 48 + value.translation.width, y: 88 + value.translation.height)
                            let canvasPoint = CGPoint(x: touchLocation.x - seabedOffset, y: touchLocation.y)

                            if let last = lastBrushPoint {
                                _ = viewModel.applyBrushSegment(from: last, to: canvasPoint, seabedY: seabedY)
                            }
                            lastBrushPoint = canvasPoint
                        }
                        .onEnded { _ in
                            lastBrushPoint = nil
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                                spongeOffset = .zero
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                AudioPlayerService.shared.playSFX("sparkle_clean")
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                    isBubblePopped = false
                                    isSpongeDragging = false
                                    popScale = 0.6
                                    popOpacity = 0.7
                                }
                            }
                        }
                )
        }
        .frame(width: 64, height: 64)
    }
}

/// Button to reset the reef to the cold open rubble state.
struct ResetColdOpenButton: View {
    @Bindable var viewModel: SandboxViewModel

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.resetToColdOpen()
            }
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.85))
                .padding(8)
                .background(Circle().fill(Color.black.opacity(0.45)))
        }
        .accessibilityLabel("Reset to cold open")
    }
}

/// 10x Fast Forward countdown button.
struct FastForwardButton: View {
    @Bindable var viewModel: SandboxViewModel

    var body: some View {
        let isActive = viewModel.isFastForward10xActive
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.activate10xFastForward(duration: 30.0)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "forward.fill")
                    .font(.subheadline.bold())
                if isActive {
                    Text("10x \(Int(ceil(viewModel.fastForwardRemainingSeconds)))s")
                        .font(.callout.monospacedDigit().bold())
                } else {
                    Text("10x FF")
                        .font(.callout.bold())
                }
            }
            .foregroundStyle(isActive ? .cyan : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive ? Color.black.opacity(0.8) : Color.black.opacity(0.45))
                    .overlay(
                        Capsule()
                            .stroke(isActive ? Color.cyan : Color.white.opacity(0.3), lineWidth: isActive ? 2 : 1)
                    )
            )
            .shadow(color: isActive ? Color.cyan.opacity(0.6) : .clear, radius: 8)
        }
        .accessibilityLabel("10x Fast Forward speed for 30 seconds")
    }
}

/// 100x Hold-to-boost turbo button.
struct DebugSpeedButton: View {
    @Bindable var viewModel: SandboxViewModel

    var body: some View {
        let isActive = viewModel.isDebug100xActive
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.subheadline.bold())
            Text("100x")
                .font(.callout.bold())
        }
        .foregroundStyle(isActive ? .orange : .white.opacity(0.9))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(isActive ? Color.orange.opacity(0.35) : Color.black.opacity(0.45))
                .overlay(
                    Capsule()
                        .stroke(isActive ? Color.orange : Color.white.opacity(0.3), lineWidth: isActive ? 2 : 1)
                )
        )
        .shadow(color: isActive ? Color.orange.opacity(0.8) : .clear, radius: 8)
        .scaleEffect(isActive ? 1.08 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isActive)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !viewModel.isDebug100xActive {
                        viewModel.setDebug100xActive(true)
                    }
                }
                .onEnded { _ in
                    viewModel.setDebug100xActive(false)
                }
        )
        .accessibilityLabel("Hold for 100x debug speed")
    }
}
