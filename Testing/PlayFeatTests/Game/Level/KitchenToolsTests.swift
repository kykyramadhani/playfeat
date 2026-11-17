//
//  KitchenToolsTests.swift
//  PlayFeatTests
//  Created by kyky on 16/11/26.
//

import Testing
@testable import PlayFeat

struct KitchenToolsTests {

    @Test func aLevelWithoutCupsSetsOutNoGlasses() {
        let tools = KitchenTools(for: makeLevel(cups: false), ownedPlates: 1, ownedGlasses: 2)

        #expect(tools.plates == 1)
        #expect(tools.glasses == 0)
    }

    @Test func aLevelWithCupsSetsOutEveryGlassOwned() {
        let tools = KitchenTools(for: makeLevel(cups: true), ownedPlates: 2, ownedGlasses: 2)

        #expect(tools.plates == 2)
        #expect(tools.glasses == 2)
    }

    /// The pool holds decoys too: level 1-1 serves only pepper flatbread,
    /// but mushrooms float by.
    @Test func theLevelsPantryIsItsBubblePool() throws {
        let level = try LevelLoader.load("1-1")

        #expect(KitchenMenu.pantry(for: level) == [KitchenMenu.rawFlatbread, KitchenMenu.pepper, KitchenMenu.mushroom])
        #expect(KitchenMenu.dishes(servedOn: level) == [KitchenMenu.pepperFlatbread])
    }
}
