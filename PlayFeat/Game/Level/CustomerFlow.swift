//
//  CustomerFlow.swift
//  PlayFeat
//  Created by kyky on 17/11/26.
//
//  What differs between a story day and the marathon: when customers step
//  up and what they order, how many fit at the counter, how they tip, which
//  ingredients the bubbles bring, and when it's all over. KitchenDay runs
//  the counter and the score the same way for both.
//

import Foundation

protocol CustomerFlow {
    /// How many customers may stand at the counter now.
    nonisolated var counterSpots: Int { get }

    /// What the bubbles can bring now, decoys included.
    nonisolated var bubblePool: [String] { get }

    /// Seconds between customers stepping up, when they come on a beat
    /// (the marathon); nil when they refill spots instead.
    nonisolated var customerSpacing: TimeInterval? { get }

    /// Customers who step up by `time`, with `atCounter` already there or waiting.
    nonisolated mutating func arrivals(at time: TimeInterval, atCounter: Int) -> [Arrival]

    /// A counter spot emptied at `time`: served or given up.
    nonisolated mutating func spotFreed(at time: TimeInterval)

    /// Everyone left the counter at `time`, neither served nor lost (a
    /// marathon's new round): customers step up again as at the opening bell.
    nonisolated mutating func counterCleared(at time: TimeInterval)

    /// A dish was served; `served` counts it.
    nonisolated mutating func dishServed(totalServed served: Int)

    /// The tip `customer` leaves when served at `time`.
    nonisolated func tip(from customer: SeatedCustomer, at time: TimeInterval) -> Int

    /// Whether play is over.
    nonisolated func isFinished(at time: TimeInterval, lostCustomers: Int, counterIsEmpty: Bool) -> Bool
}
