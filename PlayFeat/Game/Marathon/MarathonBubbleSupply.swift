//
//  MarathonBubbleSupply.swift
//  PlayFeat
//  Created by kyky on 17/11/26.
//
//  The marathon's bubbles, as in the prototype: supply follows demand. The
//  gap between bubbles shrinks as the counter needs more, faster; exactly
//  `usefulShare` of the bubbles, in a fixed pattern (UsefulBubblePattern),
//  bring the first thing still lacking; anything lacking that no
//  bubble has brought for a few seconds comes next. Never more than a
//  handful on screen at once.
//

import Foundation

nonisolated struct MarathonBubbleSupply: BubbleSupply {
    // MARK: - Dials

    static let firstGapSec: TimeInterval = 2
    static let usefulShare = 0.7
    static let intervalRange: ClosedRange<TimeInterval> = 0.8...2
    static let supplyMargin = 1.3
    static let ingredientsPerDish = 2.0
    static let guaranteeSec: TimeInterval = 3
    static let maxOnScreen = 8

    // MARK: - State

    /// The planet's opening bubbles still to send.
    private var starters: [LevelData.BubbleEntry]
    private var nextSpawnAt: TimeInterval
    private var interval = intervalRange.upperBound
    private var lastLane: Int?
    private let usefulPattern = UsefulBubblePattern(usefulShare: usefulShare)
    /// Bubbles sent after the starters, which the useful pattern counts.
    private var timedBubblesSent = 0
    /// When each ingredient last came in a bubble.
    private var lastSeen: [String: TimeInterval] = [:]
    /// Since when each ingredient has been lacking.
    private var needSince: [String: TimeInterval] = [:]

    init(starters: [LevelData.BubbleEntry]) {
        self.starters = starters
        nextSpawnAt = (starters.last?.at ?? 0) + Self.firstGapSec
    }

    mutating func bubbles(
        at time: TimeInterval,
        in context: BubbleContext,
        using generator: inout some RandomNumberGenerator
    ) -> [LevelData.BubbleEntry] {
        let needs = IngredientNeeds.missing(for: context.orders, inventory: context.kitchenItems)
            .filter(context.pool.contains)
        trackNeeds(needs, at: time)

        var due: [LevelData.BubbleEntry] = []
        while let starter = starters.first, starter.at <= time {
            starters.removeFirst()
            lastSeen[starter.ingredient] = time
            due.append(starter)
        }
        guard time >= nextSpawnAt, context.bubblesOnScreen.count < Self.maxOnScreen,
              let ingredient = pick(needs: needs, at: time, in: context, using: &generator) else { return due }

        let lane = BubbleLanes.freeLane(busy: context.busyLanes, last: lastLane, using: &generator)
        lastLane = lane
        lastSeen[ingredient] = time
        interval = Self.interval(needs: needs.count, in: context)
        nextSpawnAt = time + interval
        timedBubblesSent += 1
        return due + [LevelData.BubbleEntry(at: time, ingredient: ingredient, lane: lane)]
    }

    /// The next bubble's ingredient, or nil when the pool is empty.
    private func pick(
        needs: [String], at time: TimeInterval, in context: BubbleContext,
        using generator: inout some RandomNumberGenerator
    ) -> String? {
        let onScreen = Set(context.bubblesOnScreen)
        let overdue = needs.first { need in
            !onScreen.contains(need)
                && time - max(needSince[need] ?? time, lastSeen[need] ?? -.infinity) >= Self.guaranteeSec
        }
        if let overdue { return overdue }
        if !needs.isEmpty, usefulPattern.isUseful(bubble: timedBubblesSent) {
            return needs.first { !onScreen.contains($0) } ?? needs[0]
        }
        return context.pool.randomElement(using: &generator)
    }

    /// Seconds to the next bubble: enough to cover what the counter needs
    /// before patience runs out, and to keep up with customers coming in.
    static func interval(needs: Int, in context: BubbleContext) -> TimeInterval {
        var demand = 0.0
        if needs > 0, let patienceLeft = context.averagePatienceLeft {
            demand = Double(needs) / max(0.5, patienceLeft)
        }
        if let spacing = context.customerSpacing, spacing > 0 {
            demand = max(demand, ingredientsPerDish / spacing)
        }
        guard demand > 0 else { return intervalRange.upperBound }
        return (usefulShare / (supplyMargin * demand)).clamped(to: intervalRange)
    }

    private mutating func trackNeeds(_ needs: [String], at time: TimeInterval) {
        let current = Set(needs)
        for need in current where needSince[need] == nil { needSince[need] = time }
        needSince = needSince.filter { current.contains($0.key) }
    }
}
