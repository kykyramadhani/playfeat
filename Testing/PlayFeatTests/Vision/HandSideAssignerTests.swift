//
//  HandSideAssignerTests.swift
//  PlayFeatTests
//  Created by kyky on 16/11/26.
//

import CoreGraphics
import Testing
@testable import PlayFeat

struct HandSideAssignerTests {

    /// Shoulders 0.4 wide around the middle, wrists where given.
    private func body(left: CGPoint?, right: CGPoint?) -> HumanBodyPoseManager.BodyCandidate {
        HumanBodyPoseManager.BodyCandidate(
            head: nil,
            leftShoulder: CGPoint(x: 0.3, y: 0.7),
            rightShoulder: CGPoint(x: 0.7, y: 0.7),
            leftHip: nil,
            rightHip: nil,
            leftWrist: left,
            rightWrist: right
        )
    }

    private let reach: CGFloat = 0.24

    /// The bug this fixes: a right hand reaching across to the left of the
    /// screen, next to the left hand, used to count as a second left hand.
    @Test func aRightHandReachingAcrossStaysTheRightHand() {
        let crossed = body(left: CGPoint(x: 0.32, y: 0.5), right: CGPoint(x: 0.22, y: 0.5))
        let hands = [CGPoint(x: 0.23, y: 0.5), CGPoint(x: 0.33, y: 0.5)]

        #expect(HandSideAssigner.sides(ofHandsAt: hands, body: crossed, reach: reach) == [.right, .left])
    }

    /// The body pose runs a few frames behind the hands; both wrists lagging
    /// the same way still pair the right way round.
    @Test func twoHandsPairCorrectlyAgainstAStaleBody() {
        let stale = body(left: CGPoint(x: 0.5, y: 0.5), right: CGPoint(x: 0.8, y: 0.5))
        let hands = [CGPoint(x: 0.7, y: 0.5), CGPoint(x: 0.4, y: 0.5)]

        #expect(HandSideAssigner.sides(ofHandsAt: hands, body: stale, reach: reach) == [.right, .left])
    }

    @Test func oneHandTakesTheNearestBodyWrist() {
        let both = body(left: CGPoint(x: 0.3, y: 0.5), right: CGPoint(x: 0.7, y: 0.5))

        #expect(HandSideAssigner.sides(ofHandsAt: [CGPoint(x: 0.68, y: 0.5)], body: both, reach: reach) == [.right])
    }

    @Test func withOneWristSeenThePlacedHandSettlesTheOther() {
        let leftOnly = body(left: CGPoint(x: 0.3, y: 0.5), right: nil)
        let hands = [CGPoint(x: 0.7, y: 0.5), CGPoint(x: 0.31, y: 0.5)]

        #expect(HandSideAssigner.sides(ofHandsAt: hands, body: leftOnly, reach: reach) == [.right, .left])
    }

    /// The only wrist seen is the far one: it isn't this hand's.
    @Test func aHandOutOfReachOfEveryWristIsNotPlaced() {
        let leftOnly = body(left: CGPoint(x: 0.3, y: 0.5), right: nil)

        #expect(HandSideAssigner.sides(ofHandsAt: [CGPoint(x: 0.7, y: 0.5)], body: leftOnly, reach: reach) == [nil])
    }

    @Test func noWristsSeenPlacesNoHand() {
        let wristless = body(left: nil, right: nil)
        let hands = [CGPoint(x: 0.3, y: 0.5), CGPoint(x: 0.7, y: 0.5)]

        #expect(HandSideAssigner.sides(ofHandsAt: hands, body: wristless, reach: reach) == [nil, nil])
    }
}
