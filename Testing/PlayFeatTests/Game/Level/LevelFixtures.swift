//
//  LevelFixtures.swift
//  PlayFeatTests
//  Created by kyky on 07/11/26.
//
//  A small story level built in code, so the level-rule tests don't depend
//  on the JSON files. Override only the fields a test cares about.
//

import Foundation
@testable import PlayFeat

nonisolated func makeLevel(
    planet: Planet.ID = .kepler186f,
    counterSpots: Int = 1,
    firstOrder: String = KitchenMenu.pepperFlatbread,
    orderPool: [String: Double] = [KitchenMenu.pepperFlatbread: 1],
    angryAt: [Int] = [],
    angryEvery: Int? = nil,
    refillDelaySec: TimeInterval = 2,
    patienceSec: TimeInterval = 45,
    cups: Bool = false,
    tools: [CookingTool.Kind]? = nil,
    burnTimeMultiplier: Double = 1,
    gravity: GravityDirection = .down,
    bubbles: [LevelData.BubbleEntry] = [.init(at: 0, ingredient: KitchenMenu.rawFlatbread, lane: 2)],
    bubbleEverySec: TimeInterval = 3,
    usefulBubbleShare: Double = 0.8
) -> LevelData {
    LevelData(
        id: "test",
        name: "Test Day",
        planet: planet,
        durationSec: 90,
        refill: .init(
            counterSpots: counterSpots, refillDelaySec: refillDelaySec, firstOrder: firstOrder,
            orderPool: orderPool, angryAt: angryAt, angryEvery: angryEvery,
            patienceSec: patienceSec, angryPatienceSec: 25
        ),
        gravity: .init(direction: gravity, multiplier: 0.4),
        bubbleLifeSec: 6,
        bubbleEverySec: bubbleEverySec,
        usefulBubbleShare: usefulBubbleShare,
        cups: cups,
        tools: tools,
        burnTimeMultiplier: burnTimeMultiplier,
        starTargets: [20, 40, 60],
        energyCost: 3,
        pool: [KitchenMenu.rawFlatbread, KitchenMenu.pepper, KitchenMenu.mushroom],
        bubbles: bubbles
    )
}

/// A story day of `level` with a seeded generator, ready to tick.
@MainActor
func makeDay(_ level: LevelData = makeLevel(), plates: Int = 1, glasses: Int = 1) -> KitchenDay {
    KitchenDay(
        storyLevel: level,
        positionTypes: KitchenLayout.positionTypes,
        tools: KitchenTools(for: level, ownedPlates: plates, ownedGlasses: glasses),
        random: SeededGenerator(state: 1)
    )
}

extension CookingTool {
    /// Planet 1's grill, baking flatbreads by the prototype's timings.
    static func flatbreadGrill(burnMultiplier: Double = 1, slotCount: Int = 1) -> CookingTool {
        CookingTool(
            kind: .grill, recipes: [.flatbread], timing: .keplerKitchen,
            burnMultiplier: burnMultiplier, slotCount: slotCount
        )
    }

    /// Planet 2's pot, boiling Tide Noodles.
    static func noodlePot(burnMultiplier: Double = 1) -> CookingTool {
        CookingTool(kind: .pot, recipes: [.noodles], timing: .underwaterKitchen, burnMultiplier: burnMultiplier)
    }
}
