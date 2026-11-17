//
//  KitchenBackdrop.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  Everything behind the kitchen's bubbles, back to front: the planet through
//  the window, the customers leaning in, the counter, the props on it, and
//  the customers' order sheets.
//
//  Laid out on the 1366×1024 art in art points and scaled to fill the screen
//  as one picture, the same mapping KitchenLayout gives the scene.
//

import SwiftUI

struct KitchenBackdrop: View {
    let day: KitchenDay

    var body: some View {
        GeometryReader { proxy in
            let layout = KitchenLayout(screenSize: proxy.size)

            ZStack(alignment: .topLeading) {
                Image("KitchenWindowView").resizable()
                KitchenCustomers(day: day, part: .aliens)
                // Figma cuts the counter one point short at the bottom.
                Image("KitchenCounter").resizable()
                    .frame(width: KitchenLayout.artSize.width, height: KitchenLayout.artSize.height - 1)
                props
                KitchenCustomers(day: day, part: .orderSheets)
            }
            .frame(width: KitchenLayout.artSize.width, height: KitchenLayout.artSize.height)
            .scaleEffect(layout.scale)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var props: some View {
        ZStack(alignment: .topLeading) {
            ForEach(KitchenLayout.plates(day.tools.plates), id: \.minX) { spot in
                Image("KitchenPlate").resizable().placed(in: spot)
            }
            Image("KitchenGrill").resizable().placed(in: KitchenLayout.grill)
            ForEach(KitchenLayout.glasses(day.tools.glasses), id: \.minX) { spot in
                Image("KitchenGlass").resizable().placed(in: spot)
            }
        }
    }
}

/// The aliens and their order sheets. Split from the static art so only
/// these redraw as patience drains each frame.
private struct KitchenCustomers: View {
    enum Part { case aliens, orderSheets }

    let day: KitchenDay
    let part: Part

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(day.presentCustomers, id: \.seat) { customer in
                let seat = KitchenLayout.seats[customer.seat]
                switch part {
                case .aliens:
                    Image(seat.alienImage).resizable().placed(in: seat.alien)
                case .orderSheets:
                    OrderSheet(dish: customer.dish, patience: customer.patienceLeft(at: day.elapsed))
                        .placed(in: seat.orderSheet)
                }
            }
        }
        .frame(width: KitchenLayout.artSize.width, height: KitchenLayout.artSize.height, alignment: .topLeading)
    }
}

private extension View {
    /// Sizes and positions this view on the kitchen art.
    func placed(in rect: CGRect) -> some View {
        frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }
}
