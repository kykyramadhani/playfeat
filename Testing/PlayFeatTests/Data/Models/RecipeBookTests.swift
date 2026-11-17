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

    @Test func everyKitchenDishHasAPageInTheBook() {
        let inBook = Set(RecipeBook.entries.map(\.item))

        #expect(Set(KitchenMenu.recipes.keys).isSubset(of: inBook))
        #expect(RecipeBook.entries.count <= RecipeBook.tileCount)
    }

    /// Baked flatbread isn't put together on a station; the grill makes it.
    @Test func bakedFlatbreadIsMadeOnTheGrill() throws {
        let baked = try #require(RecipeBook.entries.first { $0.item == KitchenMenu.bakedFlatbread })

        #expect(baked.madeFrom == [.item(KitchenMenu.rawFlatbread), .tool(image: "KitchenGrill")])
        #expect(Grill.Doneness.cooked.item == KitchenMenu.bakedFlatbread)
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
