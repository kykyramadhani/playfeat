//
//  OrderSheet.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  A customer's speech bubble: what they want, and a patience bar coloured
//  by the same zones as the tip and the alien's face (green, yellow, red).
//  Once served, a check mark shows on it until it goes.
//

import SwiftUI

struct OrderSheet: View {
    let dish: String
    /// 1 when the customer sits down, 0 when they leave.
    let patience: Double
    /// The sheet stands left of its customer, so the tail points right.
    var isMirrored = false
    var isServed = false

    private static let barWidth: CGFloat = 129
    private static let checkSize: CGFloat = 54

    var body: some View {
        ZStack {
            // The bubble's tail points back up at the customer.
            Image("OrderBubble")
                .resizable()
                .frame(width: 206.9, height: 165)
                .rotationEffect(.degrees(172.74))
                .scaleEffect(x: isMirrored ? -1 : 1, y: 1)

            VStack(spacing: 22) {
                patienceBar
                dishArt
            }
            .offset(y: 4)
        }
        .frame(width: 226, height: 190)
        .overlay(alignment: .bottomTrailing) {
            if isServed { servedCheck }
        }
    }

    private var patienceBar: some View {
        Capsule()
            .fill(Color.patienceTrack)
            .frame(width: Self.barWidth, height: 11)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(Self.barColor(for: KitchenRules.PatienceZone(patienceLeft: patience)))
                    .frame(width: Self.barWidth * patience)
            }
    }

    private static func barColor(for zone: KitchenRules.PatienceZone) -> Color {
        switch zone {
        case .green: .patienceHigh
        case .yellow: .patienceMedium
        case .red: .patienceLow
        }
    }

    private var dishArt: some View {
        KitchenItemArt(item: dish)
            .frame(width: 106, height: 100)
    }

    private var servedCheck: some View {
        Image(systemName: "checkmark.circle.fill")
            .resizable()
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, Color.patienceHigh)
            .frame(width: Self.checkSize, height: Self.checkSize)
            .offset(x: -24, y: -26)
            .transition(.scale.combined(with: .opacity))
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        OrderSheet(dish: "pepperFlatbread", patience: 0.8)
        OrderSheet(dish: "pepperFlatbread", patience: 0.3, isMirrored: true)
        OrderSheet(dish: "pepperFlatbread", patience: 0.1, isServed: true)
    }
    .padding()
    .background(Color.gray)
}
