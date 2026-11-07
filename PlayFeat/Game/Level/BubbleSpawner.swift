//
//  BubbleSpawner.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  When bubbles enter and what they hold. The starter bubbles come straight
//  from the level file; after the last one the game spawns a bubble every
//  `bubbleEverySec`, and about `usefulBubbleShare` of those hold something an
//  open order needs, so a useful bubble shows up whatever order comes next.
//

import Foundation

nonisolated struct BubbleSpawner {
    private let level: LevelData

    init(level: LevelData) {
        self.level = level
    }

    var starterBubbles: [LevelData.BubbleEntry] {
        level.bubbles.sorted { $0.at < $1.at }
    }

    /// Times the game spawns a bubble of its own, from one interval after the
    /// last starter bubble until the day ends. Empty when the level sets no
    /// `bubbleEverySec`.
    var spawnTimes: [TimeInterval] {
        guard let interval = level.bubbleEverySec, interval > 0 else { return [] }
        let firstSpawn = (starterBubbles.last?.at ?? -interval) + interval
        return Array(stride(from: firstSpawn, to: level.durationSec, by: interval))
    }

    /// A bubble spawned at `time`.
    /// - Parameters:
    ///   - needed: ingredients the open orders still need.
    ///   - pantry: every ingredient this planet has; decoys come from here.
    func spawnedBubble(
        at time: TimeInterval,
        needed: Set<String>,
        pantry: Set<String>,
        using generator: inout some RandomNumberGenerator
    ) -> LevelData.BubbleEntry {
        let share = level.usefulBubbleShare ?? 0
        let decoys = pantry.subtracting(needed)
        let wantsUseful = Double.random(in: 0..<1, using: &generator) < share
        let source = (wantsUseful && !needed.isEmpty) || decoys.isEmpty ? needed : decoys
        // Sorted so a seeded generator picks the same ingredient every run.
        let ingredient = source.sorted().randomElement(using: &generator) ?? ""
        let lane = Int.random(in: 1...LevelData.BubbleEntry.laneCount, using: &generator)
        return LevelData.BubbleEntry(at: time, ingredient: ingredient, lane: lane)
    }
}
