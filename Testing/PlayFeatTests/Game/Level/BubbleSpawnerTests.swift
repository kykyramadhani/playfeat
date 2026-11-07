//
//  BubbleSpawnerTests.swift
//  PlayFeatTests
//  Created by kyky on 07/11/26.
//
//  Starter bubbles first, then one spawned bubble every `bubbleEverySec`,
//  about `usefulBubbleShare` of them useful for an open order.
//

import Testing
@testable import PlayFeat

struct BubbleSpawnerTests {

    private let pantry: Set = ["duskFlatbread", "emberPepper", "duskMushroom", "frostBerry"]

    private func spawner(usefulShare: Double) -> BubbleSpawner {
        BubbleSpawner(level: makeLevel(
            bubbles: [
                .init(at: 2, ingredient: "emberPepper", lane: 3),
                .init(at: 0, ingredient: "duskFlatbread", lane: 2)
            ],
            spawning: (everySec: 2, usefulShare: usefulShare)
        ))
    }

    @Test func starterBubblesComeInTimeOrder() {
        #expect(spawner(usefulShare: 0.6).starterBubbles.map(\.at) == [0, 2])
    }

    @Test func spawningStartsOneIntervalAfterTheLastStarterAndStopsAtTheEndOfTheDay() {
        let times = spawner(usefulShare: 0.6).spawnTimes

        #expect(times.first == 4)
        #expect(times.last == 88)
        #expect(times.count == 43)
    }

    @Test func aDayWithoutBubbleEverySecSpawnsNothing() {
        #expect(BubbleSpawner(level: makeLevel()).spawnTimes.isEmpty)
    }

    @Test func aboutTheUsefulShareOfSpawnedBubblesIsUseful() {
        let needed: Set = ["duskFlatbread", "emberPepper"]
        var generator = SeededGenerator(state: 1)
        let bubbles = (0..<1000).map { _ in
            spawner(usefulShare: 0.6).spawnedBubble(at: 0, needed: needed, pantry: pantry, using: &generator)
        }
        let usefulShare = Double(bubbles.filter { needed.contains($0.ingredient) }.count) / 1000

        #expect((0.55...0.65).contains(usefulShare))
        #expect(bubbles.allSatisfy { (1...4).contains($0.lane) })
    }

    @Test func withNothingNeededEveryBubbleIsADecoy() {
        var generator = SeededGenerator(state: 3)
        let bubble = spawner(usefulShare: 1).spawnedBubble(at: 0, needed: [], pantry: pantry, using: &generator)

        #expect(pantry.contains(bubble.ingredient))
    }

    @Test func withNoDecoysLeftEveryBubbleIsUseful() {
        var generator = SeededGenerator(state: 3)
        let bubble = spawner(usefulShare: 0).spawnedBubble(at: 0, needed: pantry, pantry: pantry, using: &generator)

        #expect(pantry.contains(bubble.ingredient))
    }
}
