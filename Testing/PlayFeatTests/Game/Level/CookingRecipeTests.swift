//
//  CookingRecipeTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 18/11/26.
//
//  Cooked items are caught raw, and a ruined item counts for nothing.
//

import Testing
@testable import PlayFeat

private typealias Menu = KitchenMenu

struct CookingRecipeTests {

    @Test(arguments: [
        (Menu.bakedFlatbread, Menu.rawFlatbread),
        (Menu.boiledNoodles, Menu.rawNoodles),
        (Menu.grilledClam, Menu.rawClam),
        (Menu.coral, Menu.coral),
    ])
    func aCookedItemIsCaughtRaw(item: String, bubble: String) {
        #expect(CookingRecipe.bubbleItem(for: item) == bubble)
    }

    @Test func clamNoodlesNeedRawNoodlesFirstThenARawClam() {
        #expect(Menu.orderedBubbleIngredients(of: Menu.clamNoodles) == [Menu.rawNoodles, Menu.rawClam])
    }

    @Test func aStarCookieStartsFromTheSeaCookie() {
        #expect(Menu.orderedBubbleIngredients(of: Menu.starCookie) == [Menu.seaCookie, Menu.starfishSugar])
    }

    @Test func boiledNoodlesInTheKitchenMeanNoNoodleBubbleIsNeeded() {
        let missing = IngredientNeeds.missing(for: [Menu.coralNoodles], inventory: [Menu.boiledNoodles])

        #expect(missing == [Menu.coral])
    }

    @Test func mushyNoodlesCountForNothing() {
        let missing = IngredientNeeds.missing(for: [Menu.coralNoodles], inventory: [Menu.mushyNoodles])

        #expect(missing == [Menu.rawNoodles, Menu.coral])
    }

    @Test(arguments: ["coralNoodles", "urchinNoodles", "clamNoodles", "starCookie"])
    func everyPlanetTwoDishHasARecipe(dish: String) {
        #expect(Menu.recipes[dish] != nil)
    }
}
