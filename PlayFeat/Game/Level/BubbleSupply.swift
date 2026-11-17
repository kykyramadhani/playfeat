//
//  BubbleSupply.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  When bubbles come and what they bring. The story days and the marathon
//  each have their own rule (StoryBubbleSupply, MarathonBubbleSupply); both
//  aim at what the counter's orders still need.
//

import Foundation

/// The kitchen as the bubble supply needs to see it, gathered by the scene
/// each frame.
nonisolated struct BubbleContext {
    /// The dishes customers at the counter ordered, oldest first.
    var orders: [String] = []
    /// Items in the kitchen other than bubbles: carried, falling, put down.
    var kitchenItems: [String] = []
    /// What the bubbles on screen hold.
    var bubblesOnScreen: [String] = []
    /// What bubbles can bring now.
    var pool: [String] = []
    /// Lanes with a bubble still near where bubbles come in.
    var busyLanes: Set<Int> = []
    /// Average seconds of patience left at the counter; nil when nobody's there.
    var averagePatienceLeft: TimeInterval?
    /// Seconds between customers, for the marathon.
    var customerSpacing: TimeInterval?
}

protocol BubbleSupply {
    /// The bubbles due by `time`.
    nonisolated mutating func bubbles(
        at time: TimeInterval,
        in context: BubbleContext,
        using generator: inout some RandomNumberGenerator
    ) -> [LevelData.BubbleEntry]
}

nonisolated enum BubbleLanes {
    static let all = Array(1...LevelData.BubbleEntry.laneCount)

    /// A lane clear of the bubbles coming in, not the one used last if
    /// another will do.
    static func freeLane(
        busy: Set<Int>, last: Int?, using generator: inout some RandomNumberGenerator
    ) -> Int {
        let clear = all.filter { !busy.contains($0) }
        let fresh = clear.filter { $0 != last }
        let options = fresh.isEmpty ? (clear.isEmpty ? all : clear) : fresh
        return options.randomElement(using: &generator) ?? 1
    }
}
