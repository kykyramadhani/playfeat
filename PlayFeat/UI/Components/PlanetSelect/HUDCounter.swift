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
    let icon: String
    let label: LocalizedStringKey
    let value: String

    private static let iconSize: CGFloat = 92

    var body: some View {
        Text(verbatim: value)
            .font(.atkinson(size: 32, weight: .bold))
            .tracking(0.64)
            .foregroundStyle(Color.purple900)
            .shadow(color: .black.opacity(0.15), radius: 0, y: 2.3)
            .frame(width: 128, height: 67)
            .padding(.leading, Self.iconSize / 2)
            .padding(.trailing, 14)
            .background(Color.neutralElevated, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 1.7))
            .shadow(color: .black.opacity(0.2), radius: 0, y: 1.9)
            .padding(.leading, Self.iconSize / 2)
            .overlay(alignment: .leading) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Self.iconSize, height: Self.iconSize)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(label))
            .accessibilityValue(Text(verbatim: value))
    }
}

#Preview {
    HUDCounter(icon: "CoinsIcon", label: "Coins", value: "276")
}
