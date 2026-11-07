//
//  FallMotionTests.swift
//  PlayFeatTests
//  Created by kyky on 07/11/26.
//
//  KH/s = multiplier x 1.25, a 0.2 s ramp to a constant speed, and lanes on
//  the edge gravity pulls away from.
//

import CoreGraphics
import Testing
@testable import PlayFeat

struct FallMotionTests {

    private let kitchenHeight: CGFloat = 1000

    private func motion(_ direction: GravityDirection, multiplier: Double = 0.4) -> FallMotion {
        FallMotion(gravity: .init(direction: direction, multiplier: multiplier), kitchenHeight: kitchenHeight)
    }

    @Test(arguments: [(0.4, 0.5), (0.5, 0.625), (0.6, 0.75), (1.0, 1.25)])
    func speedFollowsThePlanetOneTable(multiplier: Double, khPerSecond: Double) {
        #expect(abs(motion(.down, multiplier: multiplier).fallSpeedKHPerSecond - khPerSecond) < 1e-9)
    }

    @Test func releasedItemsRampUpThenHoldASteadySpeed() {
        let fall = motion(.down)

        #expect(fall.releasedVelocity(after: 0) == .zero)
        #expect(abs(fall.releasedVelocity(after: 0.1).dy - -250) < 1e-6)
        #expect(abs(fall.releasedVelocity(after: 0.2).dy - -500) < 1e-6)
        #expect(abs(fall.releasedVelocity(after: 5).dy - -500) < 1e-6)
    }

    @Test func bubblesCrossTheScreenInTheirLifetime() {
        let velocity = motion(.down).bubbleVelocity(crossing: 1200, lifeSec: 6)

        #expect(velocity == CGVector(dx: 0, dy: -200))
    }

    @Test func downGravityLanesSitOnTheTopEdgeFromTheLeft() {
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)

        #expect(GravityDirection.down.entryPoint(lane: 1, in: bounds) == CGPoint(x: 100, y: 600))
        #expect(GravityDirection.down.entryPoint(lane: 4, in: bounds) == CGPoint(x: 700, y: 600))
        #expect(GravityDirection.up.entryPoint(lane: 2, in: bounds) == CGPoint(x: 300, y: 0))
    }
}
