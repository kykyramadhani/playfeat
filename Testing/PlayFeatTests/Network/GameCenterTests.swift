//
//  GameCenterTests.swift
//  PlayFeatTests
//  Created by kyky on 21/11/26.
//
//  The Game Center IDs the app reports to, which App Store Connect must match.
//

import Testing
@testable import PlayFeat

struct GameCenterTests {

    @Test func eachPlanetsBuffetHasItsOwnLeaderboardWithoutHyphens() {
        let ids = Planet.ID.allCases.map(GameCenter.buffetLeaderboardID(on:))

        #expect(Set(ids).count == Planet.ID.allCases.count)
        #expect(ids.allSatisfy { !$0.contains("-") })
    }
}
