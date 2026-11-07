//
//  LevelFixtures.swift
//  PlayFeatTests
//  Created by kyky on 07/11/26.
//
//  A small level built in code, so the level-rule tests don't depend on the
//  JSON files. Override only the fields a test cares about.
//

import Foundation
@testable import PlayFeat

nonisolated func makeLevel(
    customers: [LevelData.CustomerEntry] = [
        .init(arriveAt: 0, type: .regular, order: "pepperFlatbread", patienceSec: 45)
    ],
    bubbles: [LevelData.BubbleEntry] = [.init(at: 0, ingredient: "duskFlatbread", lane: 2)],
    orderPool: [String: Int]? = nil,
    spawning: (everySec: TimeInterval, usefulShare: Double)? = nil
) -> LevelData {
    LevelData(
        id: "test",
        planet: "kepler-186f",
        durationSec: 90,
        gravity: .init(direction: .down, multiplier: 0.4),
        bubbleLifeSec: 6,
        storageSlots: 2,
        maxWaiting: 2,
        starTargets: [20, 40, 60],
        customers: customers,
        bubbles: bubbles,
        bubbleEverySec: spawning?.everySec,
        usefulBubbleShare: spawning?.usefulShare,
        orderPool: orderPool
    )
}
