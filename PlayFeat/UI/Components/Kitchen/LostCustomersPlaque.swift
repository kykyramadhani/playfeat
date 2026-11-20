//
//  LostCustomersPlaque.swift
//  PlayFeat
//  Created by Owen Limantoro on 20/11/26.
//
//  The marathon's lives: a metal plaque with one cross per customer the run
//  can lose. Each lost customer turns a grey cross red; when the last one
//  turns, the run is over. Figma "customer_lost_hud".
//

import SwiftUI

struct LostCustomersPlaque: View {
    let lost: Int
    let allowed: Int

    private static let crossSize: CGFloat = 45.93
    private static let crossSpacing: CGFloat = 22.6

    var body: some View {
        MetalPlaque(frame: .lostCustomers) {
            HStack(spacing: Self.crossSpacing) {
                ForEach(0..<allowed, id: \.self) { index in
                    Image("LostCustomerCross")
                        .resizable()
                        .foregroundStyle(index < lost ? Color.lostCustomerMark : Color.lostCustomerMarkSpare)
                        .frame(width: Self.crossSize, height: Self.crossSize)
                }
            }
            .animation(.easeOut(duration: 0.25), value: lost)
            .accessibilityHidden(true)
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Customers Lost"))
        .accessibilityValue(Text("\(lost) of \(allowed)"))
    }
}

#Preview {
    VStack(spacing: 20) {
        LostCustomersPlaque(lost: 0, allowed: 3)
        LostCustomersPlaque(lost: 2, allowed: 3)
    }
    .padding()
    .background(Color.gray)
}
