//
//  FuelGauge.swift
//  PlayFeat
//  Created by kyky on 16/11/26.
//
//  The spaceship's fuel gauge: a purple frame of ten bars under a star,
//  filled green from the bottom as stars are earned. Sized and tilted as
//  painted on the landed spaceship.
//

import SwiftUI

struct FuelGauge: View {
    let filledBars: Int

    static let barCount = 10
    /// Bottom bar to top: each sits 12 points higher and a hair further left,
    /// following the frame's slant.
    private static let barStep = CGSize(width: -0.28, height: -12.02)
    private static let emptyColor = Color(white: 0.85)

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("FuelGaugeFrame")
                .resizable()
            Image("FuelGaugeStar")
                .resizable()
                .frame(width: 31, height: 31)
                .rotationEffect(.degrees(-3.92))
                .position(x: 19, y: 19)
            ForEach(0..<Self.barCount, id: \.self) { index in
                bar(filled: index < filledBars)
                    .offset(
                        x: 9.04 + Self.barStep.width * CGFloat(index),
                        y: 144.71 + Self.barStep.height * CGFloat(index)
                    )
            }
        }
        .frame(width: 42.56, height: 162.5, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Fuel"))
        .accessibilityValue(Text("\(filledBars) of \(Self.barCount)"))
    }

    private func bar(filled: Bool) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(filled ? Color.green500 : Self.emptyColor)
            .frame(width: 29.4, height: 9.35)
            .rotationEffect(.degrees(-1.34))
    }
}

#Preview {
    FuelGauge(filledBars: 6).padding().background(Color.gray)
}
