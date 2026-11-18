//
//  LevelReport.swift
//  PlayFeat
//  Created by kyky on 17/11/26.
//
//  A snapshot of what a finished story day earned, shown over its frozen
//  kitchen: the recap, the stars, and how many of them are new, since only
//  those add fuel to the spaceship.
//

nonisolated struct LevelReport: Equatable {
    let level: LevelData
    let ordersDelivered: Int
    /// Points the served dishes earned.
    let dishEarnings: Int
    let ordersMissed: Int
    /// Points the missed orders actually took off.
    let pointsLost: Int
    let tips: Int
    /// Points plus tips: the day's income.
    let total: Int
    let stars: Int
    /// The level's best before this day.
    let previousBestStars: Int

    @MainActor
    init(day: KitchenDay, previousBestStars: Int) {
        level = day.level
        ordersDelivered = day.ordersDelivered
        dishEarnings = day.dishEarnings
        ordersMissed = day.ordersMissed
        pointsLost = day.pointsLost
        tips = day.tips
        total = day.total
        stars = day.stars
        self.previousBestStars = previousBestStars
    }

    /// Stars beyond the level's previous best: the ones that add fuel to the gauge.
    var newStars: Int { max(stars - previousBestStars, 0) }
}
