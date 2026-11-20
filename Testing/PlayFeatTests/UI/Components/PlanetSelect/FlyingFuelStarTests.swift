//
//  FlyingFuelStarTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 19/11/26.
//
//  Where an earned star leaves its level card and the arc it flies along
//  to the fuel gauge.
//

import CoreGraphics
import Testing
@testable import PlayFeat

struct FlyingFuelStarTests {

    private let card = CGPoint(x: 900, y: 300)
    private let gauge = CGPoint(x: 260, y: 460)

    /// Matches the stars as `LevelCard` draws them: the middle one higher.
    @Test func starsLeaveFromWhereTheCardDrawsThem() {
        let centers = (0..<3).map(LevelCard.starCenter)

        #expect(abs(centers[0].x - 47.85) < 0.01)
        #expect(abs(centers[1].x - 104.25) < 0.01)
        #expect(abs(centers[2].x - 160.65) < 0.01)
        #expect(abs(centers[0].y - 58.8) < 0.01)
        #expect(abs(centers[1].y - 42.1) < 0.01)
        #expect(centers[2].y == centers[0].y)
    }

    @Test func theArcRunsFromTheCardToTheGauge() {
        #expect(FlyingFuelStar.point(at: 0, from: card, to: gauge) == card)
        #expect(FlyingFuelStar.point(at: 1, from: card, to: gauge) == gauge)
    }

    @Test func theArcBowsUpOverBothEnds() {
        let middle = FlyingFuelStar.point(at: 0.5, from: card, to: gauge)

        #expect(middle.y < min(card.y, gauge.y))
    }
}
