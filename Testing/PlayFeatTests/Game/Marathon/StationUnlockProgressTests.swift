//
//  StationUnlockProgressTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 20/11/26.
//
//  How far up the marathon's side bar the dishes served reach, and where
//  each extra plate or glass sits on it.
//

import Testing
@testable import PlayFeat

struct StationUnlockProgressTests {

    @Test func theBarFillsTowardTheLastUnlock() {
        let progress = StationUnlockProgress(dishesServed: 7, unlocks: [6, 14])

        #expect(progress.goal == 14)
        #expect(progress.filledShare == 0.5)
    }

    @Test func eachUnlockSitsInProportionUpTheBar() {
        let progress = StationUnlockProgress(dishesServed: 0, unlocks: [6, 14])

        #expect(progress.share(at: 6) == 6.0 / 14)
        #expect(progress.share(at: 14) == 1)
    }

    @Test func theBarStaysFullOnceEverythingIsOut() {
        #expect(StationUnlockProgress(dishesServed: 30, unlocks: [6, 14]).filledShare == 1)
    }

    /// A counter with no room for more stations has nothing left to earn.
    @Test func noUnlocksLeavesTheBarFull() {
        #expect(StationUnlockProgress(dishesServed: 0, unlocks: []).filledShare == 1)
    }
}
