//
//  StoryBubbleSupply.swift
//  PlayFeat
//  Created by kyky on 17/11/26.
//
//  A story day's bubbles, as in the prototype. The level's starter bubbles
//  come first; then one every `bubbleEverySec`, for as long as the day
//  lasts (overtime included). Exactly `usefulBubbleShare` of them bring
//  something the orders still lack, counting the bubbles already on screen,
//  in a fixed pattern (UsefulBubblePattern); if none has for a while, the
//  next one does. The rest are decoys from the level's pool.
//

import Foundation

nonisolated struct StoryBubbleSupply: BubbleSupply {
    let level: LevelData

    private var starters: [LevelData.BubbleEntry]
    private var nextSpawnAt: TimeInterval
    private var lastUsefulAt: TimeInterval = 0
    private var lastLane: Int?
    private let usefulPattern: UsefulBubblePattern
    /// Bubbles sent after the starters, which the useful pattern counts.
    private var timedBubblesSent = 0

    init(level: LevelData) {
        self.level = level
        starters = level.bubbles.sorted { $0.at < $1.at }
        nextSpawnAt = (starters.last?.at ?? 0) + level.bubbleEverySec
        usefulPattern = UsefulBubblePattern(usefulShare: level.usefulBubbleShare)
    }

    mutating func bubbles(
        at time: TimeInterval,
        in context: BubbleContext,
        using generator: inout some RandomNumberGenerator
    ) -> [LevelData.BubbleEntry] {
        var due: [LevelData.BubbleEntry] = []
        while let starter = starters.first, starter.at <= time {
            starters.removeFirst()
            noteSpawn(starter.ingredient, lane: starter.lane, at: time, in: context)
            due.append(starter)
        }
        while time >= nextSpawnAt, level.bubbleEverySec > 0 {
            let ingredient = pick(at: time, in: context, using: &generator)
            let lane = BubbleLanes.freeLane(busy: context.busyLanes, last: lastLane, using: &generator)
            noteSpawn(ingredient, lane: lane, at: time, in: context)
            due.append(LevelData.BubbleEntry(at: time, ingredient: ingredient, lane: lane))
            nextSpawnAt += level.bubbleEverySec
            timedBubblesSent += 1
        }
        return due
    }

    /// What the next bubble brings: something still lacking (or, if nothing
    /// is, anything the orders use) when the useful pattern says so, and
    /// always when none has come for `maxUsefulWaitSec`; otherwise a decoy.
    private func pick(
        at time: TimeInterval, in context: BubbleContext, using generator: inout some RandomNumberGenerator
    ) -> String {
        let pool = context.pool
        let useful = usefulSet(in: context).filter(pool.contains)
        guard !useful.isEmpty else { return pool.randomElement(using: &generator) ?? KitchenMenu.rawFlatbread }

        let overdue = time + level.bubbleEverySec - lastUsefulAt > KitchenRules.maxUsefulWaitSec
        if overdue || usefulPattern.isUseful(bubble: timedBubblesSent) {
            return useful.randomElement(using: &generator) ?? pool[0]
        }
        let decoys = pool.filter { !useful.contains($0) }
        return (decoys.isEmpty ? pool : decoys).randomElement(using: &generator) ?? pool[0]
    }

    private func usefulSet(in context: BubbleContext) -> [String] {
        let missing = IngredientNeeds.missing(
            for: context.orders, inventory: context.kitchenItems + context.bubblesOnScreen
        )
        return missing.isEmpty ? IngredientNeeds.all(for: context.orders) : missing
    }

    private mutating func noteSpawn(_ ingredient: String, lane: Int, at time: TimeInterval, in context: BubbleContext) {
        let useful = usefulSet(in: context)
        if useful.isEmpty || useful.contains(ingredient) { lastUsefulAt = time }
        lastLane = lane
    }
}
