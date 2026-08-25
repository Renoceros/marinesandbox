import SwiftUI
import SwiftData

@main
struct marinesandboxApp: App {
    @State private var isSplashScreenActive: Bool = true
    var body: some Scene {
        
        WindowGroup {
            if isSplashScreenActive {
                SplashScreenView()
                    .onAppear {
                        // splash view active for 7 seconds, then transition
                        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                isSplashScreenActive = false
                            }
                        }
                    }
            } else {
                RootView()
            }
        }
        .modelContainer(for: [UserProfile.self, ReefCanvas.self, CoralFrag.self, NGOConfig.self])
    }
}
