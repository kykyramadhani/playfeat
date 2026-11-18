//
//  UsefulBubblePattern.swift
//  PlayFeat
//  Created by Owen Limantoro on 17/11/26.
//
//  Which bubbles bring something useful, as a fixed pattern rather than a
//  dice roll. A roll only hits its share on average: one day can bring a
//  streak of decoys and the next almost none. The pattern hits the share
//  exactly, spreads the decoys out, and is the same for every player.
//

nonisolated struct UsefulBubblePattern {
    /// The share of useful bubbles, in whole percent.
    let usefulPercent: Int

    init(usefulShare: Double) {
        usefulPercent = Int((usefulShare * 100).rounded()).clamped(to: 0...100)
    }

    /// Whether bubble `index` (the first is 0) is a useful one.
    ///
    /// Of the first n bubbles, n × share rounded up are useful, so the share
    /// holds after every bubble, the decoys are as far apart as they can
    /// be, and the very first bubble is useful. At 80% that is useful,
    /// useful, useful, useful, decoy, again and again.
    func isUseful(bubble index: Int) -> Bool {
        usefulCount(inFirst: index + 1) > usefulCount(inFirst: index)
    }

    /// Integer maths, so 80% of 5 is exactly 4, never 4.000000001.
    private func usefulCount(inFirst count: Int) -> Int {
        (count * usefulPercent + 99) / 100
    }
}
