//
//  HandCursorNodeTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 15/11/26.
//
//  The cartoon hand drawn over each tracked hand: which way round it is
//  drawn, and that its art is in the catalog.
//

import CoreGraphics
import Testing
import UIKit
@testable import PlayFeat

struct HandCursorNodeTests {

    private let screen = CGRect(x: 0, y: 0, width: 1000, height: 700)

    @Test func aHandFirstSeenOnTheLeftHalfIsDrawnAsALeftHand() {
        #expect(HandCursorNode.side(at: CGPoint(x: 300, y: 350), in: screen) == .left)
    }

    @Test func aHandFirstSeenOnTheRightHalfIsDrawnAsARightHand() {
        #expect(HandCursorNode.side(at: CGPoint(x: 700, y: 350), in: screen) == .right)
    }

    /// A missing image would leave the player's hands invisible during play.
    @Test(arguments: [HandCursorNode.openArt, HandCursorNode.pinchArt])
    func theHandArtExists(name: String) {
        #expect(UIImage(named: name) != nil, "missing hand art '\(name)'")
    }
}

/// Held food sits in the drawn hand's pinch: up from the palm and toward
/// the thumb side, which is the inside of the screen for either hand.
struct HandCursorPinchOffsetTests {

    @Test func aRightHandHoldsFoodUpAndToTheLeftOfThePalm() {
        let offset = HandCursorNode.pinchOffset(side: .right, bubbleRadius: 80)

        #expect(offset.dx < 0)
        #expect(offset.dy > 0)
    }

    @Test func aLeftHandHoldsFoodAtTheMirroredSpot() {
        let right = HandCursorNode.pinchOffset(side: .right, bubbleRadius: 80)
        let left = HandCursorNode.pinchOffset(side: .left, bubbleRadius: 80)

        #expect(left.dx == -right.dx)
        #expect(left.dy == right.dy)
    }

    @Test func theOffsetGrowsWithTheHand() {
        let small = HandCursorNode.pinchOffset(side: .right, bubbleRadius: 40)
        let large = HandCursorNode.pinchOffset(side: .right, bubbleRadius: 80)

        #expect(large.dy == small.dy * 2)
    }
}
