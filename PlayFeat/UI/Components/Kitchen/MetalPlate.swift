//
//  MetalPlate.swift
//  PlayFeat
//  Created by kyky on 19/11/26.
//
//  The kitchen HUD's screwed-on metal plate holding a white card, as the
//  design draws the time, points and customers-lost plaques. Only the
//  width changes between them.
//

import SwiftUI

struct MetalPlate<Content: View>: View {
    let width: CGFloat
    @ViewBuilder let content: Content

    private static var height: CGFloat { 73 }
    private static var cornerRadius: CGFloat { 13.16 }
    private static var screwSize: CGFloat { 6.83 }
    /// The card sits this far in from the plate's top-left corner.
    private static var cardInset: CGSize { CGSize(width: 15, height: 9) }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius)
        ZStack(alignment: .topLeading) {
            ForEach(screwCentres.indices, id: \.self) { index in
                Image("PopupScrew")
                    .resizable()
                    .frame(width: Self.screwSize, height: Self.screwSize)
                    .position(screwCentres[index])
            }
            card
                .offset(x: Self.cardInset.width, y: Self.cardInset.height)
        }
        .frame(width: width, height: Self.height, alignment: .topLeading)
        .background {
            shape.fill(Color.metalPlaque).paperTexture(clippedTo: shape, opacity: 0.67)
        }
        .clipShape(shape)
    }

    /// A screw in each corner, as on the 181-wide plaques.
    private var screwCentres: [CGPoint] {
        [CGPoint(x: 10.2, y: 10.2), CGPoint(x: 10.4, y: 64.9),
         CGPoint(x: width - 11.6, y: 9.4), CGPoint(x: width - 11.1, y: 64.4)]
    }

    private var card: some View {
        content
            .frame(width: width - 2 * Self.cardInset.width + 2.2, height: 56)
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
