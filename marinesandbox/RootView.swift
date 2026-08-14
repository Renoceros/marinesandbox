import SwiftUI
import SwiftData

/// **RootView: Launch Router (DEC-008, workflow §2.1)**
///
/// The entire router: a saved `ReefCanvas` exists → Coral Screen, otherwise →
/// Onboarding Page. There is no Location Selection screen and never will be one —
/// Bali/Living Seas is the implicit default (DEC-003).
///
struct RootView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var canvases: [ReefCanvas]

    var body: some View {
        if canvases.isEmpty {
            OnboardingPageView(onBegin: createCanvas)
        } else {
            // Coral Screen placeholder until Phase 3 builds SandboxView (frontend lane).
            ContentView()
        }
    }

    /// The single onboarding tap: creates the dead-rubble canvas with one surviving
    /// Staghorn frag (DEC-009) and lets the `@Query` re-route us to the Coral Screen.
    private func createCanvas() {
        SandboxViewModel(modelContext: modelContext).loadOrCreateCanvas()
    }
}

/// **Onboarding Page placeholder (workflow §2.2)**
///
/// Routing and the single-tap interaction are final; the visuals are mid-fi
/// placeholders pending Reno/Bobo's layout and Sam's dead-reef artwork.
/// Constraints that must survive the visual pass: full-bleed dead ocean, one line
/// of context, one tap, zero forms/tutorials (DEC-002, PRD §3.5–3.6).
struct OnboardingPageView: View {

    let onBegin: () -> Void

    var body: some View {
        ZStack {
            Color(white: 0.15).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Marine Sandbox")
                    .font(.largeTitle.bold())
                Text("A dead reef is waiting to come back.")
                    .font(.body)
                Text("Tap to begin")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.white)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onBegin)
    }
}

#Preview {
    RootView()
        .modelContainer(for: [UserProfile.self, ReefCanvas.self, CoralFrag.self, NGOConfig.self], inMemory: true)
}
