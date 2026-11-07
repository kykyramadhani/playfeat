//
//  LevelData.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  One day of the game as the designers write it in `level_<id>.json`.
//  Property names match the JSON fields one to one (see "6. Level data
//  files"), so the design doc and the code read the same.
//

import Foundation

nonisolated struct LevelData: Codable, Equatable {
    let id: String
    let planet: String
    let durationSec: TimeInterval
    let gravity: Gravity
    let bubbleLifeSec: TimeInterval
    let storageSlots: Int
    let maxWaiting: Int
    /// Points for 1, 2 and 3 stars, rising.
    let starTargets: [Int]
    let customers: [CustomerEntry]
    /// The starter bubbles only. Everything after them is spawned by the game.
    let bubbles: [BubbleEntry]

    /// Seconds between spawned bubbles. `nil` means the day has no spawned
    /// bubbles and runs on its starter list alone.
    let bubbleEverySec: TimeInterval?
    /// Share (0...1) of spawned bubbles that hold an ingredient an open order needs.
    let usefulBubbleShare: Double?
    /// How many of each dish the `random` customers share.
    let orderPool: [String: Int]?
}

// MARK: - Nested entries

nonisolated extension LevelData {
    struct Gravity: Codable, Equatable {
        let direction: GravityDirection
        /// Fall speed of a released ingredient; see `FallMotion`.
        let multiplier: Double
    }

    struct CustomerEntry: Codable, Equatable {
        /// The `order` value that means "take the next dish from the shuffled pool".
        static let randomOrder = "random"

        let arriveAt: TimeInterval
        let type: CustomerType
        let order: String
        let patienceSec: TimeInterval

        var takesRandomOrder: Bool { order == Self.randomOrder }
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
