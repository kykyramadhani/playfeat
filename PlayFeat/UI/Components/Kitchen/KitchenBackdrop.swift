//
//  KitchenBackdrop.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  Everything behind the kitchen's bubbles, back to front: the planet through
//  the window, the customers leaning in, the counter, the props on it, and
//  the customers' order sheets.
//
//  Laid out on the 1366×1024 art in art points and fitted to the screen as
//  one picture, the same mapping KitchenLayout gives the scene. On a screen
//  wider than the art, the truck's walls are stretched out to the edges.
//

import SwiftUI

struct KitchenBackdrop: View {
    let day: KitchenDay

    var body: some View {
        GeometryReader { proxy in
            let layout = KitchenLayout(screenSize: proxy.size)

            ZStack(alignment: .topLeading) {
                LayeredPlanetBackdrop(backdrop: planet.backdrop)
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
            .overlay { TruckWallExtension(layout: layout) }
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var planet: Planet { PlanetCatalog.planet(day.level.planet) }

    private var props: some View {
        ZStack(alignment: .topLeading) {
            ForEach(KitchenLayout.plates(day.tools.plates), id: \.minX) { spot in
                Image("KitchenPlate").resizable().placed(in: spot)
            }
            ForEach(planet.kitchen.toolKinds(on: day.level), id: \.self) { tool in
                Image(KitchenArt.image(of: tool)).resizable().placed(in: KitchenLayout.area(of: tool))
            }
            ForEach(KitchenLayout.glasses(day.tools.glasses), id: \.minX) { spot in
                Image("KitchenGlass").resizable().placed(in: spot)
            }
        }
    }
}

/// Fills the margins beside the art on a wide screen by stretching the
/// outermost strip of the counter art (truck wall above, counter below) out
/// to the screen's edges.
/// ponytail: stretched edges until the artists draw a wider truck.
private struct TruckWallExtension: View {
    /// How much of the art's outer edge is stretched, in art points: inside
    /// the wall's plain paint, clear of its shaded inner edge.
    private static let edgeStripWidth: CGFloat = 24
    /// Screen points each wall reaches over the art's edge, hiding the
    /// half-drawn edge pixels the planet would otherwise show through.
    private static let seamOverlap: CGFloat = 2

    let layout: KitchenLayout

    var body: some View {
        HStack(spacing: 0) {
            wall(keeping: .topLeading)
            Spacer(minLength: 0)
            wall(keeping: .topTrailing)
        }
    }

    /// The counter art widened until its edge strip spans the margin, cut to
    /// the margin at the `edge` side.
    private func wall(keeping edge: Alignment) -> some View {
        let width = layout.sideMargin + Self.seamOverlap
        let stretch = width / Self.edgeStripWidth
        return Image("KitchenCounter")
            .resizable()
            .frame(width: KitchenLayout.artSize.width * stretch,
                   height: (KitchenLayout.artSize.height - 1) * layout.scale)
            .offset(y: layout.viewPoint(.zero).y)
            .frame(width: width, height: layout.screenSize.height, alignment: edge)
            .clipped()
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
                    SeatedAlien(imageName: alienImage(of: customer, patienceLeft: patience), pose: seat.alienPose)
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

    /// The planet's alien for this customer, in the mood its patience is in.
    private func alienImage(of customer: SeatedCustomer, patienceLeft: Double) -> String {
        let species = PlanetCatalog.planet(day.level.planet).kitchen.alien(for: customer.type)
        return species.imageName(in: KitchenRules.PatienceZone(patienceLeft: patienceLeft))
    }
}

private extension View {
    /// Sizes and positions this view on the kitchen art.
    func placed(in rect: CGRect) -> some View {
        frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }
}
