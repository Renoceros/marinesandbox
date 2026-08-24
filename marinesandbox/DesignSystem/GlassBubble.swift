import SwiftUI

// MARK: - Canvas Overlay Metrics

/// Shared placement numbers for on-canvas guidance chrome.
public enum CanvasOverlayMetrics {

    /// Top inset for guidance text floating over the water.
    ///
    /// The HUD row in `SandboxToolOverlayView` starts at 56 and the sponge bubble
    /// is a 64pt frame, so anything above ~120 lands on top of the tool the text
    /// is usually telling the player to use. This clears it and drops the copy
    /// into the upper-mid water column.
    public static let guidanceTopPadding: CGFloat = 144
}

// MARK: - Glass Bubble Surface

/// Frosted "bubble" backing for on-canvas guidance pills and cards.
///
/// `.thinMaterial` rather than `.ultraThinMaterial`: the canvas water is a bright
/// `#3BAFED`, and against it ultraThin leaves white text badly under-contrasted.
/// The dark underlay buys the legibility back without flattening the glass.
struct GlassBubble<S: InsettableShape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        content
            .background {
                shape
                    .fill(.thinMaterial)
                    .overlay(shape.fill(Color.black.opacity(0.18)))
                    .overlay(specularHighlight)
                    .overlay(shape.strokeBorder(Color.white.opacity(0.35), lineWidth: 1.2))
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
            }
    }

    /// Light catching the upper-left of a buoyant bubble.
    ///
    /// A linear sweep rather than a radial bloom so the highlight keeps its
    /// proportions on both a one-line capsule and a three-line card — a radial
    /// gradient needs an absolute radius, which only looks right at one size.
    private var specularHighlight: some View {
        shape.fill(
            LinearGradient(
                stops: [
                    .init(color: Color.white.opacity(0.38), location: 0.0),
                    .init(color: Color.white.opacity(0.06), location: 0.45),
                    .init(color: Color.clear, location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

extension View {
    /// Wraps the view in a frosted underwater bubble of the given shape.
    func glassBubble<S: InsettableShape>(_ shape: S) -> some View {
        modifier(GlassBubble(shape: shape))
    }
}

// MARK: - PREVIEW

#Preview("Glass bubbles over water") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "3BAFED"), Color(hex: "042638")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 28) {
            Text("Flick the dead rubble away")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .glassBubble(Capsule())

            Text("A snail is eating your coral! Tap it to smush it, or flick it away.")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .glassBubble(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.horizontal, 40)
        }
    }
}
