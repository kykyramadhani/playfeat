//
//  FuelFlightPlanTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 19/11/26.
//
//  Which stars fly from the level cards to the fuel gauge, in what order,
//  and how full the gauge is before and after each lands.
//

import Testing
@testable import PlayFeat

struct FuelFlightPlanTests {

    private let levelIDs = ["a", "b", "c"]

    @Test func nothingEarnedMeansNothingFlies() {
        let progress = PlanetProgress(bestStars: [2, 1, 0])

        let plan = FuelFlightPlan(progress: progress, levelIDs: levelIDs, deliveries: [])

        #expect(plan.flights.isEmpty)
        #expect(plan.progressBefore == progress)
    }

    /// The gauge starts as it was before the level's new stars, and each
    /// star that lands adds one back.
    @Test func eachNewStarFliesFromItsPlaceOnTheCard() {
        let progress = PlanetProgress(bestStars: [3, 0, 0])
        let delivery = StarDelivery(levelID: "a", previousBest: 1, newBest: 3)

        let plan = FuelFlightPlan(progress: progress, levelIDs: levelIDs, deliveries: [delivery])

        #expect(plan.progressBefore.bestStars == [1, 0, 0])
        #expect(plan.flights.map(\.starIndex) == [1, 2])
        #expect(plan.flights.map(\.levelIndex) == [0, 0])
        #expect(plan.flights.map(\.progressAfter.bestStars) == [[2, 0, 0], [3, 0, 0]])
    }

    /// Levels played one after another with NEXT fly in the order they
    /// were played.
    @Test func severalLevelsFlyInTheOrderTheyWerePlayed() {
        let progress = PlanetProgress(bestStars: [1, 2, 0])
        let deliveries = [
            StarDelivery(levelID: "b", previousBest: 0, newBest: 2),
            StarDelivery(levelID: "a", previousBest: 0, newBest: 1),
        ]

        let plan = FuelFlightPlan(progress: progress, levelIDs: levelIDs, deliveries: deliveries)

        #expect(plan.progressBefore.bestStars == [0, 0, 0])
        #expect(plan.flights.map(\.levelIndex) == [1, 1, 0])
        #expect(plan.flights.last?.progressAfter == progress)
    }

    @Test func starsEarnedOnAnotherPlanetAreLeftOut() {
        let progress = PlanetProgress(bestStars: [1, 0, 0])
        let elsewhere = StarDelivery(levelID: "2-1", previousBest: 0, newBest: 3)

        let plan = FuelFlightPlan(progress: progress, levelIDs: levelIDs, deliveries: [elsewhere])

        #expect(plan.flights.isEmpty)
    }

    /// A level played twice before the board is seen flies once, from its
    /// first best to its last.
    @Test func twoDeliveriesForOneLevelBecomeOne() {
        let first = StarDelivery(levelID: "a", previousBest: 0, newBest: 1)
        let second = StarDelivery(levelID: "a", previousBest: 1, newBest: 3)

        #expect(first.followed(by: second) == StarDelivery(levelID: "a", previousBest: 0, newBest: 3))
    }
}
