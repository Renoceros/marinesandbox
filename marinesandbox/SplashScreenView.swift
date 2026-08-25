//
//  SplashScreenView.swift
//  marinesandbox
//
//  Created by Samantha Joice Lugay on 25/08/26.
//

import SwiftUI

struct SplashScreenView: View {
    // bg animation var
    @State var moveUp: Bool = false
    // butterfly vars
    @State var rise: Bool = false
    @State var riseStartX: CGFloat = 0
    @State var riseStartY: CGFloat = 300
    @State var riseOffset: CGSize = .zero
    @State var riseOpacity: Double = 1

    // tip text
    @State var tipText: String = ""

    // tips DB
    private let tips: [String] = [
        "When a snail appears tap it to smush it, or flick it away before it destroys your coral!",
        "Remember to keep an eye on the algae growth of your coral: it may get smothered to death!",
        "Broken fragments will float by: plant them to grow your reef!",
    ]
    
    var body: some View {
        ZStack {
            //bg
            Color(hex: "45B3EE").ignoresSafeArea()
            ZStack {
                Image("MG1")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 70)
                    .offset(y: moveUp ? -192 : -200)
                    .animation(
                        .easeInOut(duration: 1.9)
                            .repeatForever(autoreverses: true),
                        value: moveUp
                    )

                Image("BG2")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 70)
                    .offset(y: moveUp ? -260 : -250)
                    .animation(
                        .easeInOut(duration: 1.9)
                            .repeatForever(autoreverses: true),
                        value: moveUp
                    )

                Image("SF1")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 70)
                    .offset(x: moveUp ? -50 : 0, y: -420)
                    .animation(
                        .easeInOut(duration: 3.5)
                            .repeatForever(autoreverses: true),
                        value: moveUp
                    )

            }

            // sea butterfly animation
            Image("SeaButterfly")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .opacity(rise ? 0 : 1)
                .offset(
                    x: riseStartX + riseOffset.width,
                    y: riseStartY + riseOffset.height
                )
                .opacity(riseOpacity)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // reefora logo
//                Image("ReeforaLogo")
//                    .renderingMode(.template)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(height: 50)
//                    .foregroundStyle(Color(hex: "030094"))
//                    .opacity(0.8)

                Spacer()

                HStack {
                    Image("StaghornCoralPink")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    Image("BrainCoralGreen")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    Image("ElkhornCoralYellow")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    Image("TableCoralBlue")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                }

                // tip text
                Text(tipText)
                    .frame(width: 270)
                    .multilineTextAlignment(.center)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)

                    .glassBubble(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                    )
                    .padding(.horizontal, 40)

            }
            .padding(.top, 40)
            .padding(20)
            .foregroundStyle(.white)
        }
        .onAppear {
            moveUp = true
            startRisingLoop()
            tipText = tips.randomElement() ?? tips[0]
        }
    }
    
    //MARK: - FUNC: rising loop randomiser
    private func startRisingLoop() {
        // random starting point near the bottom of the screen
        riseStartX = CGFloat.random(in: -120...120)
        riseStartY = CGFloat.random(in: 250...350)
        riseOffset = .zero
        riseOpacity = 1

        withAnimation(.easeInOut(duration: Double.random(in: 3...7))) {
            riseOffset = CGSize(
                width: CGFloat.random(in: -60...60),
                height: -600
            )
            riseOpacity = 0
        }

        // schedule next loop
        Task {
            try? await Task.sleep(for: .seconds(Double.random(in: 1...5)))
            startRisingLoop()
        }
    }
}

#Preview {
    SplashScreenView()
}
