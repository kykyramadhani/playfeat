//
//  PlanetProgress.swift
//  PlayFeat
//  Created by kyky on 10/11/26.
//
//  Which of a planet's levels the player may open, from their best stars.
//  A level opens once the one before it earned at least one star, and the
//  marathon opens once the first level has. Stars fuel the spaceship: it
//  flies on with 15 of them and every level played.
//

nonisolated struct PlanetProgress: Equatable {
    /// Best stars per level, in play order.
    let bestStars: [Int]

    func isUnlocked(levelAt index: Int) -> Bool {
        index == 0 || bestStars[index - 1] > 0
    }

    var isMarathonUnlocked: Bool {
        bestStars.first.map { $0 > 0 } ?? false
    }

    /// Every level has a star. Until then the marathon may spoil what's ahead.
    var isPlanetComplete: Bool {
        bestStars.allSatisfy { $0 > 0 }
    }

    // MARK: - Leaving for the next planet

    /// Stars that fill the spaceship's tank.
    static let starsToLeave = 15

    var totalStars: Int { bestStars.reduce(0, +) }

    /// How many of a gauge's `bars` are lit: the share of `starsToLeave`
    /// earned. The last bar only lights once every level is played too, so
    /// a full gauge always means the spaceship can fly.
    func fuelBars(outOf bars: Int) -> Int {
        let share = Double(min(totalStars, Self.starsToLeave)) / Double(Self.starsToLeave)
        let lit = Int((share * Double(bars)).rounded(.down))
        return departure == .ready ? bars : min(lit, bars - 1)
    }

    enum Departure: Equatable {
        case needsFuel
        /// Enough stars, but levels are still unplayed.
        case needsEveryLevel
        case ready
    }

    var departure: Departure {
        if totalStars < Self.starsToLeave { return .needsFuel }
        return isPlanetComplete ? .ready : .needsEveryLevel
    }
}
