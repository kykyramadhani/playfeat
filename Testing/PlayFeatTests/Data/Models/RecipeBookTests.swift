//
//  RecipeBookTests.swift
//  PlayFeatTests
//  Created by kyky on 15/11/26.
//
//  The recipe book and the level introductions read from the kitchen's own
//  rules, so a recipe changed in KitchenMenu shows up wrong here first.
//

import Foundation
import Testing
@testable import PlayFeat

struct RecipeBookTests {

    private let keplerBook = RecipeBook.entries(on: .kepler186f)

    @Test(arguments: Planet.ID.allCases)
    func everyDishInTheBookIsMadeFromItsKitchenRecipe(planet: Planet.ID) {
        for entry in RecipeBook.entries(on: planet) {
            guard let recipe = KitchenMenu.recipes[entry.item] else { continue }
            let items = entry.madeFrom.compactMap { term -> String? in
                if case .item(let item) = term { return item }
                return nil
            }
            #expect(Set(items) == recipe, "the book's \(entry.item) doesn't match KitchenMenu")
        }
    }

    /// Each planet's book has a page for every dish its customers order.
    @Test(arguments: Planet.ID.allCases)
    func everyDishHasAPageInItsPlanetsBook(planet: Planet.ID) {
        let inBook = Set(RecipeBook.entries(on: planet).map(\.item))

        #expect(PlanetCatalog.planet(planet).kitchen.dishes.isSubset(of: inBook))
    }

    /// Baked flatbread isn't put together on a station; the grill makes it.
    @Test func bakedFlatbreadIsMadeOnTheGrill() throws {
        let baked = try #require(keplerBook.first { $0.item == KitchenMenu.bakedFlatbread })

        #expect(baked.madeFrom == [.item(KitchenMenu.rawFlatbread), .tool(image: "KitchenGrill")])
        #expect(CookingTool.Doneness.cooked.item(of: .flatbread) == KitchenMenu.bakedFlatbread)
    }

    /// Every page has its own line, so no placeholder text is left in.
    @Test(arguments: Planet.ID.allCases)
    func everyPageHasItsOwnDescription(planet: Planet.ID) {
        let descriptions = RecipeBook.entries(on: planet).map(\.description.key)

        #expect(Set(descriptions).count == descriptions.count)
    }

    // MARK: - Ingredients

    @Test(arguments: Planet.ID.allCases)
    func everyBubbleIngredientOfAPlanetsDishHasAPage(planet: Planet.ID) {
        let ingredients = Set(RecipeBook.entries(on: planet).filter(\.isIngredient).map(\.item))
        let dishes = PlanetCatalog.planet(planet).kitchen.dishes
        let used = Set(dishes.flatMap { KitchenMenu.bubbleIngredients(of: $0) })

        #expect(used.isSubset(of: ingredients))
    }

    @Test func anIngredientPageListsTheDishesItGoesIn() {
        #expect(RecipeBook.dishes(using: KitchenMenu.pepper).map(\.item) == [KitchenMenu.pepperFlatbread])
        #expect(RecipeBook.dishes(using: KitchenMenu.rawFlatbread).map(\.item) == [KitchenMenu.bakedFlatbread])
    }

    // MARK: - Unlocking

    @Test(arguments: Planet.ID.allCases)
    func aNewPlayersBookHasNoRecipes(planet: Planet.ID) {
        #expect(RecipeBook.entries(on: planet).filter { $0.isUnlocked(afterSeeing: []) }.isEmpty)
    }

    /// Level 1's popups open the grill and both flatbreads; the dessert
    /// waits for level 4.
    @Test func theFirstLevelUnlocksTheFlatbreads() {
        let seen = Set(KitchenIntroduction.introduced(byLevel: "1-1").map(\.id))

        let unlocked = keplerBook.filter { $0.isUnlocked(afterSeeing: seen) }.map(\.item)

        #expect(unlocked == [
            KitchenMenu.bakedFlatbread, KitchenMenu.pepperFlatbread, KitchenMenu.mushroomFlatbread,
            KitchenMenu.rawFlatbread, KitchenMenu.pepper, KitchenMenu.mushroom,
        ])
    }

    /// Otherwise a recipe could never be unlocked.
    @Test(arguments: Planet.ID.allCases)
    func everyRecipeIsUnlockedBySomeLevelOnItsPlanet(planet: Planet.ID) {
        let levelIDs = PlanetCatalog.planet(planet).levelIDs
        let seen = Set(levelIDs.flatMap { KitchenIntroduction.introduced(byLevel: $0) }.map(\.id))

        #expect(RecipeBook.entries(on: planet).allSatisfy { $0.isUnlocked(afterSeeing: seen) })
    }

    /// 2-1 opens the noodles and Coral Noodles; the clam waits for the grill
    /// on 2-3 and the cookie for 2-4.
    @Test func planetTwosFirstLevelUnlocksTheNoodlesAndCoral() {
        let seen = Set(KitchenIntroduction.introduced(byLevel: "2-1").map(\.id))

        let unlocked = RecipeBook.entries(on: .k2332b).filter { $0.isUnlocked(afterSeeing: seen) }.map(\.item)

        #expect(unlocked == [
            KitchenMenu.boiledNoodles, KitchenMenu.coralNoodles, KitchenMenu.rawNoodles, KitchenMenu.coral,
        ])
    }

    @Test func theNoodlesAreBoiledInThePotAndTheClamGrilled() throws {
        let book = RecipeBook.entries(on: .k2332b)
        let noodles = try #require(book.first { $0.item == KitchenMenu.boiledNoodles })
        let clam = try #require(book.first { $0.item == KitchenMenu.grilledClam })

        #expect(noodles.madeFrom == [.item(KitchenMenu.rawNoodles), .tool(image: KitchenArt.image(of: .pot))])
        #expect(clam.madeFrom == [.item(KitchenMenu.rawClam), .tool(image: KitchenArt.image(of: .grill))])
        #expect(CookingTool.Doneness.cooked.item(of: .noodles) == KitchenMenu.boiledNoodles)
        #expect(CookingTool.Doneness.cooked.item(of: .clam) == KitchenMenu.grilledClam)
    }

    /// The boiled noodles' page lists every noodle dish.
    @Test func theNoodlesGoInEveryNoodleDish() {
        let dishes = Set(RecipeBook.dishes(using: KitchenMenu.boiledNoodles).map(\.item))

        #expect(dishes == [KitchenMenu.coralNoodles, KitchenMenu.urchinNoodles, KitchenMenu.clamNoodles])
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

    /// Each Planet 2 day introduces the dish its first order needs.
    @Test(arguments: ["2-1", "2-3", "2-4"])
    func aPlanetTwoDayIntroducesItsFirstOrder(levelID: String) throws {
        let firstOrder = try #require(try LevelLoader.load(levelID).refill?.firstOrder)
        let introduced = KitchenIntroduction.introduced(byLevel: levelID).map(\.kind)

        #expect(introduced.contains(.menu(item: firstOrder)))
    }
}
