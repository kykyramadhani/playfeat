//
//  KitchenBackdrop.swift
//  PlayFeat
//  Created by kyky on 12/11/26.
//
//  Everything behind the kitchen's bubbles, back to front: the planet through
//  the window, the customers leaning in, the truck (walls, counter, chains),
//  the props on the counter, and the customers' order sheets.
//
//  The planet fills the screen by its layers' own fit rules, and the truck's
//  walls stick to the screen's edges (KitchenLayout.truckBands), so any
//  screen width shows a whole truck. Customers and props are laid out on the
//  1366×1024 art in art points and fitted to the screen as one picture, the
//  same mapping KitchenLayout gives the scene.
//

import SwiftUI

struct KitchenBackdrop: View {
    let day: KitchenDay

    /// The truck's layers, back to front.
    private static let truckLayers = ["TruckWall", "TruckCounter", "TruckChains"]

    var body: some View {
        GeometryReader { proxy in
            let layout = KitchenLayout(screenSize: proxy.size)

            ZStack(alignment: .topLeading) {
                LayeredPlanetBackdrop(backdrop: planet.backdrop)
                onArt(layout) { KitchenCustomers(day: day, part: .aliens, layout: layout) }
                ForEach(Self.truckLayers, id: \.self) { layer in
                    TruckLayer(imageName: layer, layout: layout)
                }
                onArt(layout) {
                    props
                    KitchenCustomers(day: day, part: .orderSheets, layout: layout)
                }
            }
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var planet: Planet { PlanetCatalog.planet(day.level.planet) }

    /// Lays `content` out on the art, in art points, and fits it to the screen.
    private func onArt(_ layout: KitchenLayout, @ViewBuilder content: () -> some View) -> some View {
        ZStack(alignment: .topLeading) { content() }
            .frame(width: KitchenLayout.artSize.width, height: KitchenLayout.artSize.height, alignment: .topLeading)
            .scaleEffect(layout.scale)
            .frame(width: layout.screenSize.width, height: layout.screenSize.height)
    }

    private var props: some View {
        let counter = planet.kitchen.counter(on: day.level)
        return ZStack(alignment: .topLeading) {
            ForEach(counter.mainStationSpots(count: day.tools.plates), id: \.minX) { spot in
                Image(counter.mainStationImage).resizable().placed(in: spot)
            }
            ForEach(planet.kitchen.toolKinds(on: day.level), id: \.self) { tool in
                Image(KitchenArt.image(of: tool)).resizable().placed(in: counter.area(of: tool))
            }
            ForEach(counter.dessertStationSpots(count: day.tools.glasses), id: \.minX) { spot in
                Image(counter.dessertStationImage).resizable().placed(in: spot)
            }
        }
    }
}

/// One truck layer, cut into KitchenLayout's bands: the outer bands at the
/// screen's edges as drawn, the plain middle widened between them.
private struct TruckLayer: View {
    /// Each band is clipped this far past its sides, so neighbouring bands
    /// overlap rather than leave a hairline seam where they meet.
    private static let seamOverlap: CGFloat = 1

    let imageName: String
    let layout: KitchenLayout

    var body: some View {
        Canvas { context, _ in
            let image = context.resolve(Image(imageName))
            for band in layout.truckBands {
                context.drawLayer { bandContext in
                    bandContext.clip(to: Path(band.screenRect.insetBy(dx: -Self.seamOverlap, dy: 0)))
                    bandContext.draw(image, in: band.layerRect)
                }
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
    let layout: KitchenLayout

    private var shown: [SeatedCustomer] {
        part == .aliens ? day.aliensOnScreen : day.orderSheetsOnScreen
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(shown, id: \.seat) { customer in
                let seat = layout.seat(at: customer.seat)
                let patience = day.patienceShown(for: customer)
                switch part {
                case .aliens:
                    SeatedAlien(imageName: alienImage(of: customer, patienceLeft: patience), pose: seat.alienPose)
                        .transition(.offset(KitchenLayout.offstageOffset(ofSeatAt: customer.seat)))
                case .orderSheets:
                    OrderSheet(dish: customer.dish, patience: patience, upgraded: day.pricing.upgradedIngredients)
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
