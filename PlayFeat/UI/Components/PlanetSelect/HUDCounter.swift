//
//  HUDCounter.swift
//  PlayFeat
//  Created by kyky on 10/11/26.
//
//  One of the cream pills along the top of the planet screen: a big icon
//  overlapping the pill's left end, with the count beside it.
//

import SwiftUI

struct HUDCounter: View {
    /// Where one counter's pieces sit in its block, as measured in Figma.
    struct Metrics {
        /// The icon's frame, from the block's top-left.
        let icon: CGRect
        let boxWidth: CGFloat
        /// How far the number sits right of the box's centre.
        let valueShift: CGFloat

        static let energy = Metrics(icon: CGRect(x: 9, y: 11, width: 87, height: 85), boxWidth: 162.5, valueShift: 0)
        static let coins = Metrics(icon: CGRect(x: 18, y: 12, width: 73, height: 69), boxWidth: 158, valueShift: 13.5)
    }

    let icon: String
    let label: LocalizedStringKey
    let value: String
    let metrics: Metrics

    /// The box starts under the icon's middle, 46 points in, and 14 down.
    private static let boxOrigin = CGPoint(x: 46, y: 14)
    private static let boxHeight: CGFloat = 67

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(verbatim: value)
                .font(.atkinson(size: 32, weight: .bold))
                .tracking(0.64)
                .foregroundStyle(Color.purple900)
                .shadow(color: .black.opacity(0.15), radius: 0, y: 2.3)
                .offset(x: metrics.valueShift)
                .frame(width: metrics.boxWidth, height: Self.boxHeight)
                .background(Color.neutralElevated, in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 1.7))
                .shadow(color: .black.opacity(0.2), radius: 0, y: 1.9)
                .offset(x: Self.boxOrigin.x, y: Self.boxOrigin.y)
            Image(icon)
                .resizable()
                .frame(width: metrics.icon.width, height: metrics.icon.height)
                .offset(x: metrics.icon.minX, y: metrics.icon.minY)
        }
        .frame(width: Self.boxOrigin.x + metrics.boxWidth, height: 92, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text(verbatim: value))
    }
}

#Preview {
    HUDCounter(icon: "HUDCoinsIcon", label: "Coins", value: "276", metrics: .coins)
        .environment(AudioManager())
}
