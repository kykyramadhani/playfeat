//
//  LevelLoaderTests.swift
//  PlayFeatTests
//  Created by kyky on 07/11/26.
//
//  The shipped level files load and pass validation, follow the playtest
//  prototype's progression, and a broken one is rejected with a reason.
//

import Foundation
import Testing
@testable import PlayFeat

struct LevelLoaderTests {

    @Test(arguments: PlanetCatalog.all.flatMap(\.levelIDs))
    func shippedLevelLoads(_ levelID: String) throws {
        let level = try LevelLoader.load(levelID)

        #expect(level.id == levelID)
        #expect(PlanetCatalog.planet(forLevel: levelID)?.id == level.planet)
    }

    /// No day orders a dish its counter has no tool to cook.
    @Test(arguments: PlanetCatalog.all.flatMap(\.levelIDs))
    func everyDishADayServesCanBeCookedThere(_ levelID: String) throws {
        let level = try LevelLoader.load(levelID)
        let kitchen = PlanetCatalog.planet(level.planet).kitchen
        let recipes = kitchen.toolKinds(on: level).flatMap { kitchen.tools[$0] ?? [] }
        let needed = KitchenMenu.dishes(servedOn: level)
            .flatMap(KitchenMenu.bubbleIngredients(of:))
            .compactMap(CookingRecipe.recipe(of:))

        #expect(needed.allSatisfy { recipe in recipes.contains { $0.raw == recipe.raw } })
    }

    // MARK: - Kepler-186f's progression, as in the prototype

    /// Levels 1–3 get the player used to the grill and the two flatbreads,
    /// with no glasses on the counter.
    @Test(arguments: ["1-1", "1-2", "1-3"])
    func theFirstLevelsServeOnlyTheFlatbreads(_ levelID: String) throws {
        let level = try LevelLoader.load(levelID)

        #expect(KitchenMenu.dishes(servedOn: level).isSubset(of: [KitchenMenu.pepperFlatbread, KitchenMenu.mushroomFlatbread]))
        #expect(!level.cups)
    }

    /// Level 4 opens on the glass dessert, still with only the green aliens.
    @Test func levelFourAddsTheDessert() throws {
        let level = try LevelLoader.load("1-4")

        #expect(level.refill?.firstOrder == KitchenMenu.slimyTentacles)
        #expect(level.cups)
        #expect(level.refill?.angryAt.isEmpty == true)
    }

    /// The angry alien is level 5's fourth customer, and every third on level 6.
    @Test func theAngryAlienArrivesFromLevelFive() throws {
        let five = try #require(try LevelLoader.load("1-5").refill)
        let six = try #require(try LevelLoader.load("1-6").refill)

        #expect(five.angryAt == [4])
        #expect(six.angryEvery == 3)
        #expect(six.counterSpots == 3)
    }

    @Test func theFirstDayBurnsSlowerAndCostsThreeEnergy() throws {
        let level = try LevelLoader.load("1-1")

        #expect(level.burnTimeMultiplier == 2)
        #expect(level.energyCost == 3)
        #expect(level.starTargets == [20, 40, 60])
    }

    // MARK: - K2-332 b's progression, as in the Planet 2 level design

    /// Gravity is flipped on every Planet 2 day, rising slowly at first.
    @Test(arguments: [("2-1", 0.4), ("2-2", 0.5), ("2-3", 0.6), ("2-6", 0.6)])
    func planetTwoBubblesRise(_ levelID: String, speed: Double) throws {
        let level = try LevelLoader.load(levelID)

        #expect(level.gravity.direction == .up)
        #expect(level.gravity.multiplier == speed)
    }

    /// The pot comes first; the grill joins on 2-3 for the clam.
    @Test func planetTwoStartsWithOnlyThePot() throws {
        #expect(try LevelLoader.load("2-1").tools == [.pot])
        #expect(try LevelLoader.load("2-3").tools == [.pot, .grill])
    }

    /// The noodles go mushy at half speed while players get used to the gravity.
    @Test func theFirstPlanetTwoDayCooksForgivingly() throws {
        #expect(try LevelLoader.load("2-1").burnTimeMultiplier == 2)
    }

    /// The cookie plate and its dessert arrive together on 2-4.
    @Test func dayFourOnPlanetTwoOpensOnTheStarCookie() throws {
        let level = try LevelLoader.load("2-4")

        #expect(level.refill?.firstOrder == KitchenMenu.starCookie)
        #expect(level.cups)
    }

    /// On 2-5 the angry alien comes fourth and orders the Star Cookie.
    @Test func theAngryAlienOnPlanetTwoOrdersTheStarCookie() throws {
        let level = try LevelLoader.load("2-5")

        #expect(level.refill?.angryAt == [4])
        #expect(PlanetCatalog.planet(level.planet).kitchen.angryOrder == KitchenMenu.starCookie)
    }

    @Test func aMissingLevelSaysWhichOne() {
        #expect {
            try LevelLoader.load("9-9")
        } throws: { error in
            guard case LevelLoaderError.fileMissing(let id) = error else { return false }
            return id == "9-9"
        }
    }

    @Test func aLaneOutsideOneToFourIsRejected() {
        let level = makeLevel(bubbles: [.init(at: 0, ingredient: KitchenMenu.pepper, lane: 5)])

        #expect(throws: LevelDataError.laneOutOfRange(5)) { try level.validate() }
    }

    @Test func anUnknownDishIsRejected() {
        let level = makeLevel(orderPool: ["sunsetSorbet": 1])

        #expect(throws: LevelDataError.unknownItem("sunsetSorbet")) { try level.validate() }
    }
}
