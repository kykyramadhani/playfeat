//
//  PlanetProgressTests.swift
//  PlayFeatTests
//  Created by kyky on 10/11/26.
//

import Testing
@testable import PlayFeat

struct PlanetProgressTests {

    @Test func theFirstLevelIsAlwaysOpen() {
        let progress = PlanetProgress(bestStars: [0, 0, 0, 0])

        #expect(progress.isUnlocked(levelAt: 0))
        #expect(!progress.isUnlocked(levelAt: 1))
    }

    @Test func aStarOnALevelOpensTheNextOne() {
        let progress = PlanetProgress(bestStars: [3, 1, 0, 0])

        #expect(progress.isUnlocked(levelAt: 2))
        #expect(!progress.isUnlocked(levelAt: 3))
    }

    @Test func theMarathonStaysLockedUntilEveryLevelHasAStar() {
        #expect(!PlanetProgress(bestStars: [3, 3, 2, 0]).isMarathonUnlocked)
        #expect(PlanetProgress(bestStars: [3, 3, 2, 1]).isMarathonUnlocked)
    }
}
