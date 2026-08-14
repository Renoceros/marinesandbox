//
//  ContentView.swift
//  marinesandbox
//
//  Created by Moreno Kristovan on 11/08/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = SandboxViewModel()

    var body: some View {
        ParallaxScrollView(scrollX: $viewModel.scrollX)
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
