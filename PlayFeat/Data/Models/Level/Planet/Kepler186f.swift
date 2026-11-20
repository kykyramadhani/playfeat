//
//  Kepler186f.swift
//  PlayFeat
//  Created by Owen Limantoro on 18/11/26.
//
//  Planet 1, Kepler-186f: one grill for the flatbreads, a plate for the
//  flatbread dishes and a glass for the dessert, with gravity pulling down.
//

import CoreGraphics

nonisolated extension Planet {
    /// Levels 1–3 teach the grill and the two flatbreads, level 4 brings the
    /// glass and its dessert, and from level 5 the angry red alien comes in.
    static let kepler186f = Planet(
        id: .kepler186f,
        name: "Kepler-186f",
        levelIDs: ["1-1", "1-2", "1-3", "1-4", "1-5", "1-6"],
        kitchen: PlanetKitchen(
            tools: [.grill: [.flatbread]],
            cookTiming: .keplerKitchen,
            mainStation: .plate,
            dessertStation: .glass,
            dishes: [KitchenMenu.pepperFlatbread, KitchenMenu.mushroomFlatbread, KitchenMenu.slimyTentacles],
            dessert: KitchenMenu.slimyTentacles,
            angryOrder: KitchenMenu.slimyTentacles,
            regularAlien: .regular,
            angryAlien: .square,
            counter: keplerCounter,
            earlyCounters: []
        ),
        buffet: keplerBuffet,
        backdrop: keplerBackdrop
    )

    /// The grill in the middle with the plate to its left and the glass to
    /// its right; a second plate goes further left, a second glass further
    /// right.
    private static let keplerCounter = CounterLayout(
        toolAreas: [.grill: CGRect(x: 551, y: 755, width: 305, height: 166)],
        mainSpots: [CGRect(x: 284, y: 778, width: 205, height: 117), CGRect(x: 42, y: 778, width: 205, height: 117)],
        dessertSpots: [
            CGRect(x: 933, y: 769, width: 150, height: 137), CGRect(x: 1130, y: 769, width: 150, height: 137),
        ],
        stationImages: (main: "KitchenPlate", dessert: "KitchenGlass")
    )

    /// A violet desert under a pale sky, with a tiny spaceship hovering far off.
    private static let keplerBackdrop = PlanetBackdrop(
        layers: [
            .init(imageName: "KeplerSky", fit: .cover),
            .init(imageName: "KeplerDunesFar", fit: .groundBand),
            .init(imageName: "KeplerDunes", fit: .groundBand),
            // Keep the near lava channel to the right of the landed ship's wheels.
            .init(imageName: "KeplerRivers", fit: .groundBand, widthScale: 1.7),
            .init(imageName: "KeplerSpaceship", fit: .topTrailing, drift: .bob(height: 8, period: 4)),
        ],
        galaxyImageName: "KeplerPlanet"
    )

    /// The prototype's marathon: flatbreads first, then from 8 dishes the
    /// dessert and one angry alien in every 5 customers.
    private static let keplerBuffet = BuffetPlan(
        stageOne: .init(
            maxWaiting: 2,
            bubblePool: keplerFlatbreadBubbles,
            group: CustomerOrder.regulars(KitchenMenu.pepperFlatbread, count: 3)
                + CustomerOrder.regulars(KitchenMenu.mushroomFlatbread, count: 2)
        ),
        stageTwo: .init(
            maxWaiting: 3,
            bubblePool: keplerFlatbreadBubbles + [KitchenMenu.tentacle, KitchenMenu.slime],
            group: [CustomerOrder(type: .angry, dish: KitchenMenu.slimyTentacles)]
                + CustomerOrder.regulars(KitchenMenu.pepperFlatbread, count: 2)
                + CustomerOrder.regulars(KitchenMenu.mushroomFlatbread, count: 1)
                + CustomerOrder.regulars(KitchenMenu.slimyTentacles, count: 1)
        ),
        stageTwoAtDishes: 8,
        firstOrder: KitchenMenu.pepperFlatbread,
        starters: [
            .init(at: 0, ingredient: KitchenMenu.rawFlatbread, lane: 2),
            .init(at: 2, ingredient: KitchenMenu.pepper, lane: 3),
        ],
        gravity: .init(direction: .down, multiplier: 0.6),
        cards: MarathonCard.Deck(
            setOffers: [
                [.fasterGrill1, .blazingPepper, .cozySeats],
                [.secondGrillSpot, .royalMushroom, .fasterGrill2],
                [.fasterGrill2, .cozySeats, .doubleTentacle],
            ],
            fallback: [
                .slimierSlime, .goldenFlatbread, .doubleTentacle, .royalMushroom,
                .blazingPepper, .cozySeats, .secondGrillSpot, .fasterGrill2,
            ]
        )
    )

    private static let keplerFlatbreadBubbles = [KitchenMenu.rawFlatbread, KitchenMenu.pepper, KitchenMenu.mushroom]
}
