//
//  LevelValidation.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  Checks a level file against the allowed values in "6. Level data files",
//  so a typo in the JSON fails loudly at load time instead of mid-game.
//

import Foundation

nonisolated enum LevelDataError: Error, Equatable {
    case storageSlotsOutOfRange(Int)
    case maxWaitingOutOfRange(Int)
    case starTargetsNotThreeRising([Int])
    case laneOutOfRange(Int)
    case usefulBubbleShareOutOfRange(Double)
    /// The number of `random` customers must equal the dishes in `orderPool`.
    case orderPoolMismatch(randomCustomers: Int, poolDishes: Int)
}

nonisolated extension LevelData {
    static let storageSlotRange = 0...4
    static let maxWaitingRange = 1...3

    /// Throws the first rule this level breaks.
    func validate() throws(LevelDataError) {
        guard Self.storageSlotRange.contains(storageSlots) else {
            throw .storageSlotsOutOfRange(storageSlots)
        }
        guard Self.maxWaitingRange.contains(maxWaiting) else {
            throw .maxWaitingOutOfRange(maxWaiting)
        }
        guard starTargets.count == 3, zip(starTargets, starTargets.dropFirst()).allSatisfy(<) else {
            throw .starTargetsNotThreeRising(starTargets)
        }
        if let badLane = bubbles.map(\.lane).first(where: { !(1...BubbleEntry.laneCount).contains($0) }) {
            throw .laneOutOfRange(badLane)
        }
        if let share = usefulBubbleShare, !(0...1).contains(share) {
            throw .usefulBubbleShareOutOfRange(share)
        }
        try validateOrderPool()
    }

    private func validateOrderPool() throws(LevelDataError) {
        let randomCustomers = customers.filter(\.takesRandomOrder).count
        let poolDishes = orderPool?.values.reduce(0, +) ?? 0
        guard randomCustomers == poolDishes else {
            throw .orderPoolMismatch(randomCustomers: randomCustomers, poolDishes: poolDishes)
        }
    }
}
