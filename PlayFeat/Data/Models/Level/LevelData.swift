//
//  LevelData.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  One story day as the designers write it in `level_<id>.json`. The fields
//  and numbers follow the playtest prototype's level config
//  (github.com/yosephadi/PlayFeat-Playtest), renamed to this game's items.
//

import Foundation

nonisolated struct LevelData: Codable, Equatable {
    let id: String
    let name: String
    let planet: String
    /// No new customer steps up after this; those at the counter can still
    /// be served (overtime).
    let durationSec: TimeInterval
    /// How customers step up to the counter. Nil for the marathon, which
    /// deals its own (see MarathonFlow).
    let refill: Refill?
    let gravity: Gravity
    /// Seconds a bubble takes to cross the window.
    let bubbleLifeSec: TimeInterval
    /// Seconds between bubbles after the starter ones.
    let bubbleEverySec: TimeInterval
    /// Share (0...1) of bubbles that bring something an order still needs.
    let usefulBubbleShare: Double
    /// Whether glasses stand on the counter: the dessert levels.
    let cups: Bool
    /// Stretches how long a baked flatbread lasts before it glows and burns.
    let burnTimeMultiplier: Double
    /// Total income for 1, 2 and 3 stars, rising.
    let starTargets: [Int]
    /// What PLAY costs, shown on the level popup. Energy isn't spent yet.
    let energyCost: Int
    /// Everything a bubble can bring, decoys included.
    let pool: [String]
    /// The starter bubbles; after them the game spawns its own.
    let bubbles: [BubbleEntry]
}

// MARK: - Nested entries

nonisolated extension LevelData {
    struct Gravity: Codable, Equatable {
        let direction: GravityDirection
        /// Fall speed of a released item; see `FallMotion`.
        let multiplier: Double
    }

    /// The refill customer flow: at most `counterSpots` customers at the
    /// counter; when one leaves, the next steps up `refillDelaySec` later.
    struct Refill: Codable, Equatable {
        let counterSpots: Int
        let refillDelaySec: TimeInterval
        /// What customer 1 orders.
        let firstOrder: String
        /// Weights the other regular customers' orders are drawn with.
        let orderPool: [String: Double]
        /// Which customers (counted from 1) are angry aliens.
        let angryAt: [Int]
        /// Every this-many-th customer is an angry alien too.
        let angryEvery: Int?
        let patienceSec: TimeInterval
        let angryPatienceSec: TimeInterval
    }

    struct BubbleEntry: Codable, Equatable {
        static let laneCount = 4

        let at: TimeInterval
        let ingredient: String
        /// 1...4, counted from the left.
        let lane: Int
    }
}

nonisolated enum CustomerType: String, Codable {
    case regular
    case angry
}
