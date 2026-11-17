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
    counterSpots: Int = 1,
    firstOrder: String = KitchenMenu.pepperFlatbread,
    orderPool: [String: Double] = [KitchenMenu.pepperFlatbread: 1],
    angryAt: [Int] = [],
    angryEvery: Int? = nil,
    refillDelaySec: TimeInterval = 2,
    patienceSec: TimeInterval = 45,
    cups: Bool = false,
    burnTimeMultiplier: Double = 1,
    bubbles: [LevelData.BubbleEntry] = [.init(at: 0, ingredient: KitchenMenu.rawFlatbread, lane: 2)],
    bubbleEverySec: TimeInterval = 3,
    usefulBubbleShare: Double = 0.8
) -> LevelData {
    LevelData(
        id: "test",
        name: "Test Day",
        planet: "kepler-186f",
        durationSec: 90,
        refill: .init(
            counterSpots: counterSpots, refillDelaySec: refillDelaySec, firstOrder: firstOrder,
            orderPool: orderPool, angryAt: angryAt, angryEvery: angryEvery,
            patienceSec: patienceSec, angryPatienceSec: 25
        ),
        gravity: .init(direction: .down, multiplier: 0.4),
        bubbleLifeSec: 6,
        bubbleEverySec: bubbleEverySec,
        usefulBubbleShare: usefulBubbleShare,
        cups: cups,
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
