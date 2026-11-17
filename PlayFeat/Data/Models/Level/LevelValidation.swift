//
//  LevelValidation.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  Checks a level file against the allowed values, so a typo in the JSON
//  fails loudly at load time instead of mid-game.
//

import Foundation

nonisolated enum LevelDataError: Error, Equatable {
    case missingRefill
    case counterSpotsOutOfRange(Int)
    case starTargetsNotThreeRising([Int])
    case laneOutOfRange(Int)
    case usefulBubbleShareOutOfRange(Double)
    case emptyOrderPool
    case unknownItem(String)
}

nonisolated extension LevelData {
    /// The counter has three aliens' worth of room.
    static let counterSpotRange = 1...3

    /// Throws the first rule this level breaks.
    func validate() throws(LevelDataError) {
        guard let refill else { throw .missingRefill }
        guard Self.counterSpotRange.contains(refill.counterSpots) else {
            throw .counterSpotsOutOfRange(refill.counterSpots)
        }
        guard starTargets.count == 3, zip(starTargets, starTargets.dropFirst()).allSatisfy(<) else {
            throw .starTargetsNotThreeRising(starTargets)
        }
        if let badLane = bubbles.map(\.lane).first(where: { !(1...BubbleEntry.laneCount).contains($0) }) {
            throw .laneOutOfRange(badLane)
        }
        guard (0...1).contains(usefulBubbleShare) else { throw .usefulBubbleShareOutOfRange(usefulBubbleShare) }
        guard refill.orderPool.values.contains(where: { $0 > 0 }) else { throw .emptyOrderPool }
        try validateItems(refill)
    }

    private func validateItems(_ refill: Refill) throws(LevelDataError) {
        let dishes = [refill.firstOrder] + refill.orderPool.keys
        if let unknown = dishes.first(where: { KitchenMenu.recipes[$0] == nil }) { throw .unknownItem(unknown) }
        let ingredients = pool + bubbles.map(\.ingredient)
        if let unknown = ingredients.first(where: { !KitchenMenu.bubbleItems.contains($0) }) {
            throw .unknownItem(unknown)
        }
    }
}
