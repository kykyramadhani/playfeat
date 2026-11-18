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
/// these redraw as patience drains each frame. An alien slides in from its
/// side of the screen and back out the same way, its face souring as its
/// patience runs low. Its order sheet fades in; once a served dish is in
/// the alien, the sheet vanishes at once and then the alien slides off
/// (KitchenDay keeps a served customer on screen until then).
private struct KitchenCustomers: View {
    enum Part { case aliens, orderSheets }

    static let slide: Animation = .easeInOut(duration: 0.6)

    let day: KitchenDay
    let part: Part

    private var shown: [SeatedCustomer] {
        part == .aliens ? day.aliensOnScreen : day.orderSheetsOnScreen
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(shown, id: \.seat) { customer in
                let seat = KitchenLayout.seats[customer.seat]
                let patience = day.patienceShown(for: customer)
                switch part {
                case .aliens:
                    Image(seat.alienImage(patienceLeft: patience)).resizable().placed(in: seat.alien)
                        .transition(.offset(seat.offstageOffset))
                case .orderSheets:
                    OrderSheet(dish: customer.dish, patience: patience)
                        .placed(in: seat.orderSheet)
                        .transition(.asymmetric(insertion: .opacity, removal: .identity))
                }
            }
        }
        .frame(width: KitchenLayout.artSize.width, height: KitchenLayout.artSize.height, alignment: .topLeading)
        .animation(Self.slide, value: shown.map(\.seat))
    }
}

private extension View {
    /// Sizes and positions this view on the kitchen art.
    func placed(in rect: CGRect) -> some View {
        frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }
}
