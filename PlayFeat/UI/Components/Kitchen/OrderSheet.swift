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

    private static let barWidth: CGFloat = 129
    /// Below this the bar turns red.
    private static let lowPatience = 0.35

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
                    .fill(patience < Self.lowPatience ? Color.patienceLow : Color.patienceHigh)
                    .frame(width: Self.barWidth * patience)
            }
    }

    private var dishArt: some View {
        let layers = KitchenArt.dishLayers(dish)
        return ZStack {
            ForEach(layers.indices, id: \.self) { index in
                Image(layers[index])
                    .resizable()
                    .scaledToFit()
                    .frame(width: index == 0 ? 100 : 80, height: index == 0 ? 100 : 60)
            }
        }
        .frame(width: 106, height: 100)
    }
}

#Preview {
    OrderSheet(dish: "pepperFlatbread", patience: 0.8)
        .padding()
        .background(Color.gray)
}
