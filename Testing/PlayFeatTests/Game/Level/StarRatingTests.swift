//
//  StarRatingTests.swift
//  PlayFeatTests
//  Created by kyky on 07/11/26.
//

import Testing
@testable import PlayFeat

struct StarRatingTests {

    @Test(arguments: [(0, 0), (19, 0), (20, 1), (40, 2), (59, 2), (60, 3), (200, 3)])
    func starsFollowTheTargets(score: Int, stars: Int) {
        #expect(StarRating.stars(for: score, targets: [20, 40, 60]) == stars)
    }
}
