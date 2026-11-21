//
//  StoryAchievement.swift
//  PlayFeat
//  Created by kyky on 21/11/26.
//
//  The story mode's Game Center achievements, drawn from the story's levels
//  and rules: clearing each level (named after it), finishing or perfecting
//  a planet, and what a single day can show off (three stars, no customer
//  lost, an angry alien calmed, the dessert served, a full tip jar). Worked
//  out from saved progress and the day just played, so it is plain data and
//  can be tested without GameKit.
//

import Foundation

/// What a finished story day showed, as the achievements read it.
nonisolated struct StoryDayRecap: Equatable {
    let stars: Int
    let ordersDelivered: Int
    let ordersMissed: Int
    let tips: Int
    let angryCustomersServed: Int
    let dessertsServed: Int
}

nonisolated enum StoryAchievement: String, CaseIterable {
    // Clearing each level (at least one star), named after the level.
    case firstSale, hotGrill, twoToppings, somethingSweet, theAngryAlien, doubleTrouble
    case upsideDown, pickATopping, grillIsBack, sweetStars, angryAgain, fullTide
    // A whole planet cleared, then perfected with three stars on every level.
    case keplerChef, keplerStarChef, tideChef, tideStarChef
    // One day's showing.
    case perfectDay, nobodyLeftHungry, calmTheStorm, sweetTooth, tipJar
    // Stars across the whole story.
    case starCollector, superstar

    /// Must match the achievement ID in App Store Connect character for character.
    var identifier: String { "com.reability.playfeat.achievement.\(rawValue)" }

    static let tipJarTips = 20
    static let starCollectorStars = 10
    static let superstarStars = 30
    /// A day without a lost customer counts only once a few were served.
    static let nobodyLeftHungryServed = 3

    /// The level whose clearing earns each per-level achievement.
    static let levelClears: [String: StoryAchievement] = [
        "1-1": .firstSale, "1-2": .hotGrill, "1-3": .twoToppings,
        "1-4": .somethingSweet, "1-5": .theAngryAlien, "1-6": .doubleTrouble,
        "2-1": .upsideDown, "2-2": .pickATopping, "2-3": .grillIsBack,
        "2-4": .sweetStars, "2-5": .angryAgain, "2-6": .fullTide,
    ]

    /// Everything earned after `recap`'s day, `bestStars` being each level's
    /// best stars with that day already saved.
    static func earned(after recap: StoryDayRecap, bestStars: (String) -> Int) -> Set<StoryAchievement> {
        earnedByProgress(bestStars: bestStars).union(earnedByDay(recap))
    }

    /// What the saved stars show: levels and planets cleared, star totals.
    static func earnedByProgress(bestStars: (String) -> Int) -> Set<StoryAchievement> {
        var earned = Set(levelClears.filter { bestStars($0.key) > 0 }.values)
        for (planet, cleared, perfected) in planetAchievements {
            let stars = PlanetCatalog.planet(planet).levelIDs.map(bestStars)
            if stars.allSatisfy({ $0 > 0 }) { earned.insert(cleared) }
            if stars.allSatisfy({ $0 >= StarRating.maxStars }) { earned.insert(perfected) }
        }
        let totalStars = Planet.ID.allCases.flatMap { PlanetCatalog.planet($0).levelIDs }.map(bestStars).reduce(0, +)
        if totalStars >= starCollectorStars { earned.insert(.starCollector) }
        if totalStars >= superstarStars { earned.insert(.superstar) }
        return earned
    }

    /// What the day itself showed off.
    static func earnedByDay(_ recap: StoryDayRecap) -> Set<StoryAchievement> {
        var earned: Set<StoryAchievement> = []
        if recap.stars >= StarRating.maxStars { earned.insert(.perfectDay) }
        if recap.ordersMissed == 0, recap.ordersDelivered >= nobodyLeftHungryServed { earned.insert(.nobodyLeftHungry) }
        if recap.angryCustomersServed > 0 { earned.insert(.calmTheStorm) }
        if recap.dessertsServed > 0 { earned.insert(.sweetTooth) }
        if recap.tips >= tipJarTips { earned.insert(.tipJar) }
        return earned
    }

    private static let planetAchievements: [(Planet.ID, StoryAchievement, StoryAchievement)] = [
        (.kepler186f, .keplerChef, .keplerStarChef),
        (.k2332b, .tideChef, .tideStarChef),
    ]
}
