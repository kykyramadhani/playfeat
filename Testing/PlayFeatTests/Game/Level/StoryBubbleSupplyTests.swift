//
//  StoryBubbleSupplyTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 17/11/26.
//
//  A story day's bubbles follow the level's useful share exactly, whatever
//  the random generator rolls.
//

import Foundation
import Testing
@testable import PlayFeat

struct StoryBubbleSupplyTests {

    /// One Pepper Flatbread ordered and nothing made yet, so a flatbread or
    /// a pepper is useful and a mushroom is the only decoy.
    private let waitingForPepperFlatbread = BubbleContext(
        orders: [KitchenMenu.pepperFlatbread],
        pool: [KitchenMenu.rawFlatbread, KitchenMenu.pepper, KitchenMenu.mushroom]
    )

    /// The ingredients of the bubbles sent after the starters, one per
    /// `bubbleEverySec` (3 s) for `count` bubbles.
    private func timedBubbles(count: Int, seed: UInt64) -> [String] {
        var supply = StoryBubbleSupply(level: makeLevel(bubbleEverySec: 3, usefulBubbleShare: 0.8))
        var generator = SeededGenerator(state: seed)
        _ = supply.bubbles(at: 0, in: waitingForPepperFlatbread, using: &generator)
        return (1...count).flatMap { step in
            supply.bubbles(at: TimeInterval(step) * 3, in: waitingForPepperFlatbread, using: &generator)
        }.map(\.ingredient)
    }

    @Test(arguments: [1, 2, 3] as [UInt64])
    func everyFifthBubbleIsTheDecoyAtEightyPercent(seed: UInt64) {
        let bubbles = timedBubbles(count: 10, seed: seed)
        let decoyPlaces = bubbles.indices.filter { bubbles[$0] == KitchenMenu.mushroom }

        #expect(decoyPlaces == [4, 9])
    }
}
