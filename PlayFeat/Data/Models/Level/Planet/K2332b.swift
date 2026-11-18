//
//  K2332b.swift
//  PlayFeat
//  Created by Owen Limantoro on 18/11/26.
//
//  Planet 2, K2-332 b: an underwater food truck where gravity is flipped
//  (set per level file). A pot boils the Tide Noodles and, from 2-3, the
//  Planet 1 grill opens the Lantern Clam. Noodle dishes are built in a bowl
//  and the Star Cookie on a cookie plate. Numbers follow the Planet 2 level
//  design (Adi, 18 Nov); all are placeholders until the first test.
//

import CoreGraphics

nonisolated extension Planet {
    /// 2-1 brings the pot and the noodles, 2-2 a second topping, 2-3 the
    /// grill and the clam, 2-4 the cookie, 2-5 the angry alien, and 2-6 a
    /// third customer with an angry alien every third.
    static let k2332b = Planet(
        id: .k2332b,
        name: "K2-332 b",
        levelIDs: ["2-1", "2-2", "2-3", "2-4", "2-5", "2-6"],
        kitchen: PlanetKitchen(
            tools: [.pot: [.noodles], .grill: [.clam]],
            cookTiming: .underwaterKitchen,
            mainStation: .bowl,
            dessertStation: .cookiePlate,
            dishes: [
                KitchenMenu.coralNoodles, KitchenMenu.urchinNoodles, KitchenMenu.clamNoodles, KitchenMenu.starCookie,
            ],
            dessert: KitchenMenu.starCookie,
            angryOrder: KitchenMenu.starCookie,
            regularAlien: .triangle,
            angryAlien: .square
        ),
        buffet: k2332bBuffet,
        backdrop: k2332bBackdrop
    )

    /// The sea floor: two sand banks, a tentacle at the right and coral at
    /// the left. The bubble clusters are painted into the water, so the
    /// whole water layer bobs until they come as their own layer.
    private static let k2332bBackdrop = PlanetBackdrop(
        layers: [
            .init(imageName: "K2332bWater", fit: .cover, drift: .bob(height: 6, period: 7)),
            .init(imageName: "K2332bSandFar", fit: .groundBand),
            .init(imageName: "K2332bSand", fit: .groundBand),
            .init(imageName: "K2332bTentacle", fit: .bottomTrailing, drift: .sway(degrees: 3, pivot: tentacleRoot, period: 5)),
            .init(imageName: "K2332bCoral", fit: .bottomLeading, drift: .sway(degrees: 2, pivot: coralRoot, period: 6)),
        ],
        galaxyImageName: "K2332bPlanet"
    )

    /// Where the tentacle comes in from the right edge, and the coral's foot.
    private static let tentacleRoot = CGPoint(x: 1, y: 0.53)
    private static let coralRoot = CGPoint(x: 0.05, y: 1)

    /// Coral and Urchin Noodles first; from 8 dishes the clam joins, with one
    /// angry and one regular Star Cookie in every 5 customers (the regular
    /// one is the design's open-question proposal). Rising at 0.6×.
    private static let k2332bBuffet = BuffetPlan(
        stageOne: .init(
            maxWaiting: 2,
            bubblePool: [KitchenMenu.rawNoodles, KitchenMenu.coral, KitchenMenu.urchin],
            group: CustomerOrder.regulars(KitchenMenu.coralNoodles, count: 3)
                + CustomerOrder.regulars(KitchenMenu.urchinNoodles, count: 2)
        ),
        stageTwo: .init(
            maxWaiting: 3,
            bubblePool: [
                KitchenMenu.rawNoodles, KitchenMenu.coral, KitchenMenu.urchin, KitchenMenu.rawClam,
                KitchenMenu.seaCookie, KitchenMenu.starfishSugar,
            ],
            group: [CustomerOrder(type: .angry, dish: KitchenMenu.starCookie)]
                + CustomerOrder.regulars(KitchenMenu.coralNoodles, count: 1)
                + CustomerOrder.regulars(KitchenMenu.urchinNoodles, count: 1)
                + CustomerOrder.regulars(KitchenMenu.clamNoodles, count: 1)
                + CustomerOrder.regulars(KitchenMenu.starCookie, count: 1)
        ),
        stageTwoAtDishes: 8,
        firstOrder: KitchenMenu.coralNoodles,
        starters: [
            .init(at: 0, ingredient: KitchenMenu.rawNoodles, lane: 2),
            .init(at: 2, ingredient: KitchenMenu.coral, lane: 3),
        ],
        gravity: .init(direction: .up, multiplier: 0.6),
        // ponytail: no Planet 2 ingredient cards are designed yet, so only the
        // tool and seat cards are dealt.
        cards: MarathonCard.Deck(
            setOffers: [
                [.fasterPot, .cozySeats, .fasterGrill1],
                [.secondGrillSpot, .fasterGrill1, .fasterGrill2],
                [.fasterGrill2, .cozySeats, .secondGrillSpot],
            ],
            fallback: [.fasterPot, .cozySeats, .secondGrillSpot, .fasterGrill1, .fasterGrill2]
        )
    )
}
