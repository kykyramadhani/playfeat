//
//  PlanetCatalogTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 18/11/26.
//
//  The planet lookups the gameplay leans on: which planet a day is on, the
//  day after it, its number, and what each planet's angry alien orders.
//

import Testing
@testable import PlayFeat

struct PlanetCatalogTests {

    @Test func aPlanetTwoDayIsOnK2332b() {
        #expect(PlanetCatalog.planet(forLevel: "2-3")?.id == .k2332b)
    }

    @Test func aLevelOnNoPlanetHasNoPlanet() {
        #expect(PlanetCatalog.planet(forLevel: "marathon") == nil)
    }

    @Test func theNextDayStaysOnTheSamePlanet() {
        #expect(PlanetCatalog.nextLevelID(after: "2-1") == "2-2")
    }

    @Test(arguments: ["1-6", "2-6"])
    func thereIsNoDayAfterAPlanetsLast(levelID: String) {
        #expect(PlanetCatalog.nextLevelID(after: levelID) == nil)
    }

    @Test func dayNumbersCountFromOneOnEachPlanet() {
        #expect(PlanetCatalog.dayNumber(of: "2-4") == 4)
    }

    @Test func everyPlanetIDHasItsDefinition() {
        #expect(PlanetCatalog.all.map(\.id) == Planet.ID.allCases)
    }

    @Test(arguments: [
        (Planet.ID.kepler186f, KitchenMenu.slimyTentacles), (.k2332b, KitchenMenu.starCookie)
    ])
    func eachPlanetsAngryAlienOrdersItsDessert(planet: Planet.ID, angryOrder: String) {
        #expect(PlanetCatalog.planet(planet).kitchen.angryOrder == angryOrder)
    }

    @Test func noLevelIsOnTwoPlanets() {
        let levelIDs = PlanetCatalog.all.flatMap(\.levelIDs)
        #expect(Set(levelIDs).count == levelIDs.count)
    }
}
