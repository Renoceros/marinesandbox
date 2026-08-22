import SwiftUI

/// **DiagnosticCardView: 5-Year Reflection Modal (workflow §3.1, Kolb cycle)**
///
/// Plain-language reflection card presented after Fast Forward.
struct DiagnosticCardView: View {
    @Bindable var viewModel: SandboxViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("5 Years Later")
                    .font(.title2.bold())
                if let message = viewModel.diagnosticMessage {
                    Text(message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                Button("Back to my reef") {
                    withAnimation { viewModel.dismissDiagnosticCard() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .transition(.opacity)
    }
}
