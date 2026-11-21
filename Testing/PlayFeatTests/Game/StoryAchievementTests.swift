//
//  StoryAchievementTests.swift
//  PlayFeatTests
//  Created by kyky on 21/11/26.
//
//  Which story achievements a day earns: from the saved stars (levels,
//  planets, star totals) and from the day itself.
//

import Testing
@testable import PlayFeat

struct StoryAchievementTests {

    private func recap(
        stars: Int = 1, delivered: Int = 5, missed: Int = 1, tips: Int = 0, angry: Int = 0, desserts: Int = 0
    ) -> StoryDayRecap {
        StoryDayRecap(
            stars: stars, ordersDelivered: delivered, ordersMissed: missed,
            tips: tips, angryCustomersServed: angry, dessertsServed: desserts
        )
    }

    private func stars(_ levels: [String: Int]) -> (String) -> Int {
        { levels[$0] ?? 0 }
    }

    @Test func clearingALevelEarnsTheAchievementNamedAfterIt() {
        let earned = StoryAchievement.earnedByProgress(bestStars: stars(["1-1": 1]))

        #expect(earned == [.firstSale])
    }

    @Test func clearingEveryLevelOfAPlanetMakesYouItsChef() {
        let allCleared = Dictionary(uniqueKeysWithValues: Planet.kepler186f.levelIDs.map { ($0, 1) })

        let earned = StoryAchievement.earnedByProgress(bestStars: stars(allCleared))

        #expect(earned.contains(.keplerChef))
        #expect(!earned.contains(.keplerStarChef))
    }

    @Test func threeStarsOnEveryLevelOfAPlanetMakesYouItsStarChef() {
        let perfect = Dictionary(uniqueKeysWithValues: Planet.kepler186f.levelIDs.map { ($0, 3) })

        let earned = StoryAchievement.earnedByProgress(bestStars: stars(perfect))

        #expect(earned.isSuperset(of: [.keplerChef, .keplerStarChef, .starCollector]))
        #expect(!earned.contains(.tideChef))
    }

    @Test func aDaysShowingEarnsItsAchievements() {
        let day = recap(stars: 3, delivered: 6, missed: 0, tips: 20, angry: 1, desserts: 1)

        #expect(StoryAchievement.earnedByDay(day)
            == [.perfectDay, .nobodyLeftHungry, .calmTheStorm, .sweetTooth, .tipJar])
    }

    /// A day with a customer lost, or too few served, isn't "nobody left hungry".
    @Test func nobodyLeftHungryNeedsAFewServedAndNoneLost() {
        #expect(!StoryAchievement.earnedByDay(recap(missed: 1)).contains(.nobodyLeftHungry))
        #expect(!StoryAchievement.earnedByDay(recap(delivered: 2, missed: 0)).contains(.nobodyLeftHungry))
    }

    @Test func everyStoryLevelHasItsOwnAchievement() {
        let storyLevels = Planet.ID.allCases.flatMap { PlanetCatalog.planet($0).levelIDs }

        #expect(Set(storyLevels) == Set(StoryAchievement.levelClears.keys))
        #expect(Set(StoryAchievement.levelClears.values).count == storyLevels.count)
    }
}
