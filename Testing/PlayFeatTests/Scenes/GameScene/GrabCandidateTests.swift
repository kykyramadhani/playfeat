//
//  GrabCandidateTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 10/11/26.
//
//  Which bubble a grab takes when the hand touches more than one: the one
//  nearest where the hand grips, not the one nearest any of its joints.
//

import Testing
import CoreGraphics
@testable import PlayFeat

struct GrabCandidateTests {

    private let lower = (position: CGPoint(x: 0, y: 0), reach: CGFloat(50))
    private let upper = (position: CGPoint(x: 0, y: 120), reach: CGFloat(50))

    /// Reaching up: the wrist sits on the lower bubble's centre while the
    /// pinching fingertips are at the upper bubble's edge.
    @Test func reachingUpTakesTheBubbleAtTheFingertips() {
        let wrist = CGPoint(x: 0, y: 0)
        let fingertips = CGPoint(x: 0, y: 80)

        let index = GameScene.grabIndex(of: [lower, upper], touchedBy: [wrist, fingertips], grabPoint: fingertips)

        #expect(index == 1)
    }

    /// Nearest the grab point doesn't matter if nothing of the hand touches it.
    @Test func anUntouchedBubbleIsNeverTaken() {
        let wrist = CGPoint(x: 0, y: 0)
        let grabPoint = CGPoint(x: 0, y: 100)

        let index = GameScene.grabIndex(of: [lower, upper], touchedBy: [wrist], grabPoint: grabPoint)

        #expect(index == 0)
    }

    @Test func aHandTouchingNothingTakesNothing() {
        let farAway = CGPoint(x: 500, y: 500)

        #expect(GameScene.grabIndex(of: [lower, upper], touchedBy: [farAway], grabPoint: farAway) == nil)
    }
}
