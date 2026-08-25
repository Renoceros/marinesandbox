import SwiftData
import SwiftUI

/// **PestTooltipView: One-time snail warning (DEC-012)**
///
/// Shown the first time a pest reaches the reef. Three ways out, so it can never
/// strand itself on the canvas: a tap, killing the snail (`SandboxPestView` calls
/// `dismissPestTooltip()` on both the smush and the flick paths), or the
/// auto-dismiss timer below.
///
/// The "already seen" flag is view-owned rather than view-model state. It is UI
/// history, not reef simulation — keeping it here means the pest spawn logic in
/// `SandboxViewModel+CareLoop` needs no knowledge of it. `SandboxToolOverlayView`
/// clears the flag when the reef drops back to the cold open, so the next visitor
/// on an exhibition device still gets the hint.
struct PestTooltipView: View {

    /// `UserDefaults` key for the one-time flag. Read by `SandboxToolOverlayView`,
    /// which re-arms the hint on reset.
    static let hasSeenKey = "hasSeenPestTooltip"

    /// How long the tooltip lingers before fading out on its own.
    private static let autoDismissDelay: Duration = .seconds(6)

    @Bindable var viewModel: SandboxViewModel

    @AppStorage(PestTooltipView.hasSeenKey) private var hasSeenTooltip = false

    /// Whether this encounter earns the tooltip.
    ///
    /// Resolved in `.task` rather than straight from `hasSeenTooltip`, because the
    /// task *writes* that flag — reading it directly in `body` would hide the
    /// tooltip on the very render that was supposed to show it.
    private enum Visibility { case undecided, showing, suppressed }
    @State private var visibility: Visibility = .undecided

    var body: some View {
        VStack {
            if visibility == .showing {
                Text("A snail is eating your coral! Tap it to smush it, or flick it away.")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .glassBubble(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .padding(.horizontal, 40)
                    .contentShape(Rectangle())
                    .onTapGesture { dismiss() }
                    .transition(.opacity)
            }
            Spacer()
        }
        .padding(.top, CanvasOverlayMetrics.guidanceTopPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(visibility == .showing)
        .task { await runLifecycle() }
    }

    private func runLifecycle() async {
        // Met a snail before: hand the canvas straight back without ever drawing.
        guard !hasSeenTooltip else {
            visibility = .suppressed
            dismiss()
            return
        }

        hasSeenTooltip = true
        withAnimation(.easeOut(duration: 0.35)) { visibility = .showing }

        // `Task.sleep` throws the moment the view goes away — a tap or a smushed
        // snail tears the tooltip down early — so the cancellation check below is
        // what stops a dead timer from firing a second dismiss.
        try? await Task.sleep(for: Self.autoDismissDelay)
        guard !Task.isCancelled else { return }
        dismiss()
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.35)) {
            viewModel.dismissPestTooltip()
        }
    }
}

// MARK: - PREVIEW

#Preview("Pest tooltip over water") {
    let container = try! ModelContainer(
        for: ReefCanvas.self, CoralFrag.self, UserProfile.self, NGOConfig.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let viewModel = SandboxViewModel(modelContext: container.mainContext)

    // The preview exercises the first-encounter path; the flag is real
    // `UserDefaults`, so clear it or a previous run leaves the canvas empty.
    UserDefaults.standard.set(false, forKey: PestTooltipView.hasSeenKey)

    return ZStack {
        LinearGradient(
            colors: [Color(hex: "3BAFED"), Color(hex: "042638")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        PestTooltipView(viewModel: viewModel)
    }
}
