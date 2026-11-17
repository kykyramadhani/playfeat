//
//  ShopUpgradeTests.swift
//  PlayFeatTests
//  Created by kyky on 15/11/26.
//

import Testing
@testable import PlayFeat

struct ShopUpgradeTests {

    private let tentacle = ShopUpgrade(image: "Tentacle", stat: .coins, values: [7, 14], prices: [210], isUnlocked: true)

    @Test func theNextLevelIsOfferedAtItsPrice() {
        #expect(tentacle.offer(atLevel: 0, coins: 300) == .buy(from: 7, to: 14, price: 210, canAfford: true))
        #expect(tentacle.offer(atLevel: 0, coins: 100) == .buy(from: 7, to: 14, price: 210, canAfford: false))
    }

    @Test func pastTheLastLevelItIsMaxedOut() {
        #expect(tentacle.offer(atLevel: 1, coins: 999) == .maxed(value: 14))
    }

    @Test func aLockedUpgradeOffersNothing() {
        let coral = ShopUpgrade(image: "CoralLettuce", stat: .coins, values: [5, 10], prices: [150], isUnlocked: false)

        #expect(coral.offer(atLevel: 0, coins: 999) == .locked)
    }
}
