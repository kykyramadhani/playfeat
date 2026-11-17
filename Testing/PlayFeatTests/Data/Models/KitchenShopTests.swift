//
//  KitchenShopTests.swift
//  PlayFeatTests
//  Created by kyky on 16/11/26.
//
//  What dishes are worth and what the planet-1 shop sells, by the playtest
//  prototype's numbers.
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

    /// On Kepler-186f the tools tab only adds a plate and a glass: the grill
    /// upgrade waits for planet 2.
    @Test func theToolsTabSellsOnlyThePlateAndGlass() {
        #expect(KitchenShop.upgrades(on: .ingredients).count == KitchenShop.ingredientUpgrades.count)
        #expect(KitchenShop.upgrades(on: .tools).map(\.id) == [KitchenShop.plateID, KitchenShop.glassID])
    }

    @Test func anIngredientUpgradeStartsFromItsBaseValue() throws {
        let mushroom = try #require(KitchenShop.ingredientUpgrades.first { $0.ingredient == KitchenMenu.mushroom })

        #expect(mushroom.upgrade.values == [15, 24])
    }
}
