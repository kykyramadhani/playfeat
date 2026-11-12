//
//  PlanetProgress.swift
//  PlayFeat
//  Created by kyky on 10/11/26.
//
//  Which of a planet's levels the player may open, from their best stars.
//  A level opens once the one before it earned at least one star, and the
//  marathon opens once every level has.
//

nonisolated struct PlanetProgress {
    /// Best stars per level, in play order.
    let bestStars: [Int]

    func isUnlocked(levelAt index: Int) -> Bool {
        index == 0 || bestStars[index - 1] > 0
    }

    var isMarathonUnlocked: Bool {
        bestStars.allSatisfy { $0 > 0 }
    }
}
