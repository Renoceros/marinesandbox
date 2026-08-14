import SwiftUI
import SwiftData

/// **ContentView: Coral Screen entry**
///
/// The Coral Screen is `SandboxView`; this shell exists so the router (`RootView`)
/// has a stable target while the screen's internals evolve.
///
struct ContentView: View {
    var body: some View {
        SandboxView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProfile.self, ReefCanvas.self, CoralFrag.self, NGOConfig.self], inMemory: true)
}
