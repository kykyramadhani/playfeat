//
//  MetalPlaque.swift
//  PlayFeat
//  Created by Owen Limantoro on 20/11/26.
//
//  The kitchen HUD's screwed-on metal plate holding a white card, as the
//  design draws the time and coin counters and the marathon's lost
//  customers. Each plaque's measurements are a `MetalPlaqueFrame` preset.
//

import SwiftUI

struct MetalPlaque<Content: View>: View {
    let frame: MetalPlaqueFrame
    @ViewBuilder let content: Content

    private static var cornerRadius: CGFloat { 13.16 }
    /// Where the card sits on the plate, on every plaque.
    private static var cardOffset: CGSize { CGSize(width: 15, height: 9) }
    private static var screwSize: CGFloat { 6.83 }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius)
        return ZStack(alignment: .topLeading) {
            ForEach(frame.screws.indices, id: \.self) { index in
                Image("PopupScrew")
                    .resizable()
                    .frame(width: Self.screwSize, height: Self.screwSize)
                    .position(frame.screws[index])
                    .accessibilityHidden(true)
            }
            card
                .offset(Self.cardOffset)
        }
        .frame(width: frame.plateSize.width, height: frame.plateSize.height, alignment: .topLeading)
        .background {
            shape.fill(Color.metalPlaque).paperTexture(clippedTo: shape, opacity: 0.67)
        }
        .clipShape(shape)
    }

    private var card: some View {
        content
            .frame(width: frame.cardSize.width, height: frame.cardSize.height)
            .background {
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .fill(
                        Color.neutralBackground
                            .shadow(.inner(color: .black.opacity(0.37), radius: 1.1, y: -1.1))
                            .shadow(.inner(color: .black.opacity(0.39), radius: 0.7, y: 1.1))
                    )
            }
    }
}

// MARK: - Plaques in the design

/// One plaque's measurements, in design points. Outside `MetalPlaque`
/// because a generic type can't hold the stored presets.
struct MetalPlaqueFrame {
    let plateSize: CGSize
    let cardSize: CGSize
    /// The screws' centres on the plate.
    let screws: [CGPoint]

    /// The time and coin counters at the bottom left.
    static let counter = Self(
        plateSize: CGSize(width: 181, height: 73),
        cardSize: CGSize(width: 153.2, height: 56),
        screws: [CGPoint(x: 10.2, y: 10.2), CGPoint(x: 10.4, y: 64.9), CGPoint(x: 169.4, y: 9.4),
                 CGPoint(x: 169.9, y: 64.4)]
    )

    /// The marathon's lost customers at the bottom right (Figma
    /// "customer_lost_hud").
    static let lostCustomers = Self(
        plateSize: CGSize(width: 282.82, height: 73.28),
        cardSize: CGSize(width: 253.03, height: 56.5),
        screws: [CGPoint(x: 10.25, y: 10.25), CGPoint(x: 10.42, y: 64.87), CGPoint(x: 271.36, y: 8.15),
                 CGPoint(x: 272.42, y: 64.15)]
    )
}

#Preview {
    VStack(spacing: 20) {
        MetalPlaque(frame: .counter) { Text(verbatim: "01:30") }
        MetalPlaque(frame: .lostCustomers) { Text(verbatim: "✕ ✕ ✕") }
    }
    .font(.atkinson(size: 32, weight: .bold))
    .padding()
    .background(Color.gray)
}
