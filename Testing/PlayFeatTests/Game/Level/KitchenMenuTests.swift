//
//  KitchenMenuTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 12/11/26.
//
//  Which ingredients make which dish.
//

import Testing
@testable import PlayFeat

struct KitchenMenuTests {

    @Test func theOrderOfIngredientsDoesNotMatter() {
        #expect(KitchenMenu.dish(madeFrom: [KitchenMenu.pepper, KitchenMenu.bakedFlatbread])
            == KitchenMenu.pepperFlatbread)
    }

    @Test func aRecipeNeedsExactlyItsIngredients() {
        #expect(KitchenMenu.dish(madeFrom: [KitchenMenu.bakedFlatbread]) == nil)
        #expect(KitchenMenu.dish(madeFrom: [KitchenMenu.bakedFlatbread, KitchenMenu.pepper, KitchenMenu.mushroom])
            == nil)
    }

    @Test func aDuplicateIngredientMakesNothing() {
        #expect(KitchenMenu.dish(madeFrom: [KitchenMenu.slime, KitchenMenu.slime, KitchenMenu.tentacle]) == nil)
    }

    /// Every dish a level can order has a recipe.
    @Test(arguments: ["pepperFlatbread", "mushroomFlatbread", "sunsetSorbet"])
    func everyOrderableDishHasARecipe(dish: String) {
        #expect(KitchenMenu.recipes[dish] != nil)
    }
}
