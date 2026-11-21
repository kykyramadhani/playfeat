//
//  OrderSheet.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  A customer's speech bubble: what they want, and a patience bar that
//  drains green to red while they wait.
//

import SwiftUI

struct OrderSheet: View {
    let dish: String
    /// 1 when the customer sits down, 0 when they leave.
    let patience: Double
    /// Upgraded ingredients, so the order shows the dish as it will be made.
    var upgraded: Set<String> = []

    private static let barWidth: CGFloat = 129
    private var patienceColor: Color {
        switch KitchenRules.PatienceZone(patienceLeft: patience) {
        case .green: .patienceHigh
        case .yellow: .starYellow
        case .red: .patienceLow
        }
    }

    var body: some View {
        ZStack {
            // The bubble's tail points back up-left at the customer.
            Image("OrderBubble")
                .resizable()
                .frame(width: 206.9, height: 165)
                .rotationEffect(.degrees(172.74))

            VStack(spacing: 22) {
                patienceBar
                dishArt
            }
            .offset(y: 4)
        }
        .frame(width: 226, height: 190)
    }

    private var patienceBar: some View {
        Capsule()
            .fill(Color.patienceTrack)
            .frame(width: Self.barWidth, height: 11)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(patienceColor)
                    .frame(width: Self.barWidth * patience)
            }
    }

    private var dishArt: some View {
        KitchenItemArt(item: dish, upgraded: upgraded)
            .frame(width: 106, height: 100)
    }
}

#Preview {
    OrderSheet(dish: "pepperFlatbread", patience: 0.8)
        .padding()
        .background(Color.gray)
}
