//
//  CounterLayoutTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 20/11/26.
//
//  Where each planet's counter puts its tools and stations: the order the
//  plates and glasses come out in, where food cooks, and which counter a
//  level is played on.
//

import CoreGraphics
import Testing
@testable import PlayFeat

struct CounterLayoutTests {

    private let kepler = Planet.kepler186f.kitchen.counter
    private let k2332b = Planet.k2332b.kitchen

    // MARK: - Plates and glasses

    /// One plate stands beside the grill; a second goes further left, and
    /// never more than the counter has spots for.
    @Test func plateSpotsKeepTheFirstPlateBesideTheGrill() {
        let one = kepler.mainStationSpots(count: 1)
        let two = kepler.mainStationSpots(count: 2)

        #expect(one.count == 1)
        #expect(two[0] == one[0])
        #expect(two[1].maxX < two[0].minX)
        #expect(kepler.mainStationSpots(count: 5).count == kepler.maxMainStations)
    }

    /// On Planet 2 a second bowl goes to the right of the first, at the
    /// same height, on every counter; there is only ever one cookie plate.
    @Test func planetTwosSecondBowlStandsRightOfTheFirst() {
        for counter in [k2332b.counter] + k2332b.earlyCounters {
            let bowls = counter.mainStationSpots(count: 2)

            #expect(bowls.count == 2)
            #expect(bowls[0].maxX < bowls[1].minX)
            #expect(bowls[0].minY == bowls[1].minY)
        }
        #expect(k2332b.counter.maxDessertStations == 1)
    }

    @Test func glassSpotsKeepTheFirstGlassBesideTheGrill() {
        let two = kepler.dessertStationSpots(count: 2)

        #expect(kepler.dessertStationSpots(count: 1) == [two[0]])
        #expect(two[0].maxX < two[1].minX)
        #expect(kepler.dessertStationSpots(count: 0).isEmpty)
    }

    // MARK: - Cooking

    /// The grill is drawn in perspective: its hot ring sits up and left of
    /// the box's centre, where Planet 1's design puts it.
    @Test func theGrillsRingIsWhereTheArtDrawsIt() {
        let grill = kepler.area(of: .grill)

        #expect(kepler.cookingSpots(on: .grill, count: 1) == [CGPoint(x: 719, y: 813)])
        #expect(CounterLayout.grillRing(in: grill) == CGPoint(x: 719, y: 813))
    }

    @Test func twoGrillSlotsSitEitherSideOfTheRing() {
        let ring = CounterLayout.grillRing(in: kepler.area(of: .grill))
        let slots = kepler.cookingSpots(on: .grill, count: 2)

        #expect(slots[0].x < ring.x && ring.x < slots[1].x)
        #expect(slots.allSatisfy { $0.y == ring.y })
    }

    @Test func noodlesBoilInTheMiddleOfThePot() {
        let pot = k2332b.counter.area(of: .pot)

        #expect(k2332b.counter.cookingSpots(on: .pot, count: 1) == [pot.center])
    }

    /// A counter without a tool gives it nowhere to stand, so nothing lands on it.
    @Test func aToolNotOnTheCounterHasNoArea() {
        #expect(kepler.area(of: .pot).isNull)
    }

    // MARK: - Which counter

    @Test(arguments: ["2-1", "2-2"])
    func thePotLevelsUseThePotOnlyCounter(levelID: String) throws {
        let counter = k2332b.counter(on: try LevelLoader.load(levelID))

        #expect(counter.tools == [.pot])
        #expect(counter != k2332b.counter)
    }

    @Test(arguments: ["2-3", "2-4", "2-6"])
    func fromTheGrillOnTheFullCounterIsUsed(levelID: String) throws {
        #expect(k2332b.counter(on: try LevelLoader.load(levelID)) == k2332b.counter)
    }

    /// Every story level finds its cooking tools, a main station and, when
    /// it serves the dessert, a dessert station on its counter.
    @Test func everyLevelsCounterHasWhatTheLevelNeeds() throws {
        for planet in PlanetCatalog.all {
            for levelID in planet.levelIDs {
                let level = try LevelLoader.load(levelID)
                let counter = planet.kitchen.counter(on: level)

                #expect(Set(planet.kitchen.toolKinds(on: level)).isSubset(of: counter.tools), "\(levelID)")
                #expect(counter.maxMainStations >= 1, "\(levelID)")
                #expect(!level.cups || counter.maxDessertStations >= 1, "\(levelID)")
            }
        }
    }

    /// On Planet 2's full counter the grill, the pot, both bowls and the
    /// cookie plate stand side by side, none over another.
    @Test func planetTwosToolsAndStationsDoNotOverlap() {
        let counter = k2332b.counter
        let spots = [counter.area(of: .grill), counter.area(of: .pot)]
            + counter.mainStationSpots(count: 2) + counter.dessertStationSpots(count: 1)

        for (index, spot) in spots.enumerated() {
            for other in spots[(index + 1)...] {
                #expect(!spot.intersects(other))
            }
        }
    }
}
