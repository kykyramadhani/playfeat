//
//  RecipeBookTests.swift
//  PlayFeatTests
//  Created by kyky on 15/11/26.
//
//  The recipe book and the level introductions read from the kitchen's own
//  rules, so a recipe changed in KitchenMenu shows up wrong here first.
//

import Testing
@testable import PlayFeat

struct RecipeBookTests {

    @Test func everyDishInTheBookIsMadeFromItsKitchenRecipe() {
        for entry in RecipeBook.entries {
            guard let recipe = KitchenMenu.recipes[entry.item] else { continue }
            let items = entry.madeFrom.compactMap { term -> String? in
                if case .item(let item) = term { return item }
                return nil
            }
            #expect(Set(items) == recipe, "the book's \(entry.item) doesn't match KitchenMenu")
        }
    }

    /// The book is Kepler-186f's; Planet 2's dishes get theirs with its screens.
    @Test func everyKeplerDishHasAPageInTheBook() {
        let inBook = Set(RecipeBook.entries.map(\.item))

        #expect(Planet.kepler186f.kitchen.dishes.isSubset(of: inBook))
    }

    /// Baked flatbread isn't put together on a station; the grill makes it.
    @Test func bakedFlatbreadIsMadeOnTheGrill() throws {
        let baked = try #require(RecipeBook.entries.first { $0.item == KitchenMenu.bakedFlatbread })

        #expect(baked.madeFrom == [.item(KitchenMenu.rawFlatbread), .tool(image: "KitchenGrill")])
        #expect(CookingTool.Doneness.cooked.item(of: .flatbread) == KitchenMenu.bakedFlatbread)
    }

    // MARK: - Ingredients

    @Test func everyBubbleIngredientOfAKeplerDishHasAPage() {
        let ingredients = Set(RecipeBook.entries.filter(\.isIngredient).map(\.item))
        let used = Set(Planet.kepler186f.kitchen.dishes.flatMap { KitchenMenu.bubbleIngredients(of: $0) })

        #expect(used.isSubset(of: ingredients))
    }

    @Test func anIngredientPageListsTheDishesItGoesIn() {
        #expect(RecipeBook.dishes(using: KitchenMenu.pepper).map(\.item) == [KitchenMenu.pepperFlatbread])
        #expect(RecipeBook.dishes(using: KitchenMenu.rawFlatbread).map(\.item) == [KitchenMenu.bakedFlatbread])
    }

    // MARK: - Unlocking

    @Test func aNewPlayersBookHasNoRecipes() {
        #expect(RecipeBook.entries.filter { $0.isUnlocked(afterSeeing: []) }.isEmpty)
    }

    /// Level 1's popups open the grill and both flatbreads; the dessert
    /// waits for level 4.
    @Test func theFirstLevelUnlocksTheFlatbreads() {
        let seen = Set(KitchenIntroduction.introduced(byLevel: "1-1").map(\.id))

        let unlocked = RecipeBook.entries.filter { $0.isUnlocked(afterSeeing: seen) }.map(\.item)

        #expect(unlocked == [
            KitchenMenu.bakedFlatbread, KitchenMenu.pepperFlatbread, KitchenMenu.mushroomFlatbread,
            KitchenMenu.rawFlatbread, KitchenMenu.pepper, KitchenMenu.mushroom,
        ])
    }

    /// Otherwise a recipe could never be unlocked.
    @Test func everyRecipeIsUnlockedBySomeKeplerLevel() {
        let seen = Set(Planet.kepler186f.levelIDs.flatMap { KitchenIntroduction.introduced(byLevel: $0) }.map(\.id))

        #expect(RecipeBook.entries.allSatisfy { $0.isUnlocked(afterSeeing: seen) })
    }

    @Test func theFirstLevelIntroducesTheGrillAndBothFlatbreads() {
        let ids = KitchenIntroduction.introduced(byLevel: "1-1").map(\.id)

        #expect(ids == [
            "tool.grill", "menu.\(KitchenMenu.pepperFlatbread)", "menu.\(KitchenMenu.mushroomFlatbread)",
        ])
        #expect(KitchenIntroduction.introduced(byLevel: "9-9").isEmpty)
    }

    @Test func levelFourIntroducesTheGlassAndItsDessert() {
        let ids = KitchenIntroduction.introduced(byLevel: "1-4").map(\.id)

        #expect(ids == ["tool.glass", "menu.\(KitchenMenu.slimyTentacles)"])
    }
}
