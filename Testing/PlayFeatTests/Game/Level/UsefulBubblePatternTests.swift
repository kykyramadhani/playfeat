//
//  UsefulBubblePatternTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 17/11/26.
//
//  The useful-bubble share as a fixed pattern: exact, evenly spread, and
//  starting with a useful bubble.
//

import Testing
@testable import PlayFeat

struct UsefulBubblePatternTests {

    private func pattern(_ share: Double, bubbles: Int) -> [Bool] {
        let pattern = UsefulBubblePattern(usefulShare: share)
        return (0..<bubbles).map { pattern.isUseful(bubble: $0) }
    }

    @Test func eightyPercentIsFourUsefulThenOneDecoy() {
        #expect(pattern(0.8, bubbles: 10) == [true, true, true, true, false, true, true, true, true, false])
    }

    /// The shares the levels and Buffet use land exactly, not just on average.
    @Test(arguments: [0.8, 0.7, 0.65, 0.6])
    func everyHundredBubblesHoldExactlyTheShare(share: Double) {
        let useful = pattern(share, bubbles: 100).filter { $0 }.count

        #expect(useful == Int((share * 100).rounded()))
    }

    /// At these shares a decoy is always followed by a useful bubble, so the
    /// player never sees a streak of decoys.
    @Test(arguments: [0.8, 0.7, 0.65, 0.6])
    func decoysNeverComeTwiceInARow(share: Double) {
        let bubbles = pattern(share, bubbles: 100)
        let decoyPairs = zip(bubbles, bubbles.dropFirst()).filter { !$0 && !$1 }

        #expect(decoyPairs.isEmpty)
    }

    @Test func theFirstBubbleIsUseful() {
        #expect(pattern(0.1, bubbles: 1) == [true])
    }

    @Test func noShareMeansOnlyDecoys() {
        #expect(!pattern(0, bubbles: 20).contains(true))
    }

    @Test func aFullShareMeansOnlyUsefulBubbles() {
        #expect(!pattern(1, bubbles: 20).contains(false))
    }
}
