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

    @Test func theMarathonOpensOnceTheFirstLevelHasAStar() {
        #expect(!PlanetProgress(bestStars: [0, 0, 0, 0, 0, 0]).isMarathonUnlocked)
        #expect(PlanetProgress(bestStars: [1, 0, 0, 0, 0, 0]).isMarathonUnlocked)
    }

    /// Until every level has a star, playing the marathon may spoil what's ahead.
    @Test func thePlanetIsCompleteOnlyWhenEveryLevelHasAStar() {
        #expect(!PlanetProgress(bestStars: [3, 3, 2, 1, 1, 0]).isPlanetComplete)
        #expect(PlanetProgress(bestStars: [3, 3, 2, 1, 1, 1]).isPlanetComplete)
    }

    /// The gauge fills by the share of 15 stars earned: 6 of 15 lights 4 of 10 bars.
    @Test func theGaugeFillsByTheShareOfFifteenStars() {
        #expect(PlanetProgress(bestStars: [3, 3, 0, 0, 0, 0]).fuelBars(outOf: 10) == 4)
        #expect(PlanetProgress(bestStars: [0, 0, 0, 0, 0, 0]).fuelBars(outOf: 10) == 0)
    }

    /// 15 stars from five levels isn't a full tank while the sixth is unplayed.
    @Test func theLastBarWaitsForEveryLevelToBePlayed() {
        let fiveLevels = PlanetProgress(bestStars: [3, 3, 3, 3, 3, 0])

        #expect(fiveLevels.fuelBars(outOf: 10) == 9)
        #expect(fiveLevels.departure == .needsEveryLevel)
    }

    @Test func fewerThanFifteenStarsNeedsFuel() {
        #expect(PlanetProgress(bestStars: [3, 3, 3, 2, 1, 1]).departure == .needsFuel)
    }

    @Test func fifteenStarsAndEveryLevelPlayedFillTheTank() {
        let ready = PlanetProgress(bestStars: [3, 3, 3, 3, 2, 1])

        #expect(ready.departure == .ready)
        #expect(ready.fuelBars(outOf: 10) == 10)
    }
}
