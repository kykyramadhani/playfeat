//
//  KitchenShopTests.swift
//  PlayFeatTests
//  Created by kyky on 16/11/26.
//
//  What dishes are worth and what each planet's shop sells, by the playtest
//  prototype's numbers and Planet 2's design doc.
//

import Testing
@testable import PlayFeat

struct KitchenShopTests {

    /// A dish is worth its ingredients: flatbread 10 + pepper 10, flatbread
    /// 10 + mushroom 15, tentacle 10 + slime 5.
    @Test func dishesAreWorthTheirIngredients() {
        #expect(DishPricing.unupgraded.pay(for: KitchenMenu.pepperFlatbread) == 20)
        #expect(DishPricing.unupgraded.pay(for: KitchenMenu.mushroomFlatbread) == 25)
        #expect(DishPricing.unupgraded.pay(for: KitchenMenu.slimyTentacles) == 15)
    }

    /// The baked flatbread is priced as the raw one the bubble brought.
    @Test func anUpgradedIngredientRaisesEveryDishItGoesIn() {
        let pricing = DishPricing.unupgraded.upgrading([KitchenMenu.rawFlatbread: 16])

        #expect(pricing.pay(for: KitchenMenu.pepperFlatbread) == 26)
        #expect(pricing.pay(for: KitchenMenu.mushroomFlatbread) == 31)
        #expect(pricing.pay(for: KitchenMenu.slimyTentacles) == 15)
    }

    /// The extra glass goes on sale after 1-4, the extra plate after 1-1.
    @Test func toolsGoOnSaleAfterTheirLevel() throws {
        let plate = try #require(KitchenShop.upgrade(KitchenShop.plateID))
        let glass = try #require(KitchenShop.upgrade(KitchenShop.glassID))

        #expect(plate.isUnlocked(clearedLevels: ["1-1"]))
        #expect(!glass.isUnlocked(clearedLevels: ["1-1", "1-2", "1-3"]))
        #expect(glass.isUnlocked(clearedLevels: ["1-4"]))
    }

    /// Past the last level an upgrade stays at its top value.
    @Test func anUpgradesValueStopsAtItsTop() throws {
        let plate = try #require(KitchenShop.upgrade(KitchenShop.plateID))

        #expect(plate.value(atLevel: 0) == 1)
        #expect(plate.value(atLevel: 5) == 2)
    }

    /// Each ingredient card shows the premium look the upgrade buys.
    @Test func keplersIngredientCardsShowThePremiumArt() {
        let images = KitchenShop.upgrades(on: .ingredients, planet: .kepler186f).map(\.image)

        #expect(images == [
            "PremiumFlatbreadRaw", "PremiumPepper", "PremiumGlowyMushroom", "PremiumTentacle", "PremiumSlime",
        ])
    }

    /// Planet 2's shop sells the six ingredients its design doc lists.
    @Test func planetTwosIngredientCardsShowThePremiumArt() {
        let images = KitchenShop.upgrades(on: .ingredients, planet: .k2332b).map(\.image)

        #expect(images == [
            "PremiumNoodlesRaw", "PremiumCoral", "PremiumUrchin", "PremiumClamRaw", "PremiumSeaCookie",
            "PremiumStarfishSugar",
        ])
    }

    /// On Kepler-186f the tools tab only adds a plate and a glass: the grill
    /// upgrade waits for planet 2.
    @Test func keplersToolsTabSellsOnlyThePlateAndGlass() {
        #expect(KitchenShop.upgrades(on: .tools, planet: .kepler186f).map(\.id) == [
            KitchenShop.plateID, KitchenShop.glassID,
        ])
    }

    /// Planet 2 has room for a second bowl but only ever one cookie plate.
    @Test func planetTwosToolsTabSellsOnlyTheBowl() {
        #expect(KitchenShop.upgrades(on: .tools, planet: .k2332b).map(\.id) == [KitchenShop.bowlID])
    }

    /// Every upgrade is sold on exactly one planet's shop.
    @Test func everyUpgradeIsSoldOnOnePlanet() {
        let sold = Planet.ID.allCases.flatMap { planet in
            KitchenUpgrade.Tab.allCases.flatMap { KitchenShop.upgrades(on: $0, planet: planet) }
        }

        #expect(sold.map(\.id).sorted() == KitchenShop.upgrades.map(\.id).sorted())
    }

    /// The extra bowl goes on sale after 2-1, the first noodle day.
    @Test func theExtraBowlGoesOnSaleAfterTwoOne() throws {
        let bowl = try #require(KitchenShop.upgrade(KitchenShop.bowlID))

        #expect(!bowl.isUnlocked(clearedLevels: ["1-1", "1-2", "1-3", "1-4", "1-5", "1-6"]))
        #expect(bowl.isUnlocked(clearedLevels: ["2-1"]))
        #expect(bowl.planet == .k2332b)
    }

    @Test func eachPlanetsStationsComeFromItsOwnShop() {
        #expect(KitchenShop.mainStationID(on: .kepler186f) == KitchenShop.plateID)
        #expect(KitchenShop.dessertStationID(on: .kepler186f) == KitchenShop.glassID)
        #expect(KitchenShop.mainStationID(on: .k2332b) == KitchenShop.bowlID)
        #expect(KitchenShop.dessertStationID(on: .k2332b) == nil)
    }

    @Test func anIngredientUpgradeStartsFromItsBaseValue() throws {
        let mushroom = try #require(KitchenShop.ingredientUpgrades.first { $0.ingredient == KitchenMenu.mushroom })

        #expect(mushroom.upgrade.values == [15, 24])
    }

    /// Planet 2's prices and values, from its design doc.
    @Test func planetTwosClamUpgradeFollowsTheDesignDoc() throws {
        let clam = try #require(KitchenShop.ingredientUpgrades.first { $0.ingredient == KitchenMenu.rawClam })

        #expect(clam.upgrade.values == [15, 20])
        #expect(clam.upgrade.prices == [40])
        #expect(clam.upgrade.isUnlocked(clearedLevels: ["2-3"]))
    }
}
