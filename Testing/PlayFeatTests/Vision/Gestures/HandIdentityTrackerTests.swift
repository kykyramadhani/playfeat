//
//  HandIdentityTrackerTests.swift
//  PlayFeatTests
//
//  The frame-to-frame rules of HandIdentityTracker: IDs that stick, the grace
//  period that lets a hand coast through dropped frames, cursor smoothing and
//  the pinch needing several frames to commit. Fed made-up readings, so no
//  camera is involved.
//

import Testing
import CoreGraphics
@testable import PlayFeat

struct HandIdentityTrackerTests {

    /// One frame's reading for a hand at `point`. `pinch` is the thumb-to-index
    /// gap in palm lengths: 1.0 is wide open, 0.1 is pinched.
    private func reading(at point: CGPoint, pinch: CGFloat = 1.0) -> HandClassifier.Classification {
        HandClassifier.Classification(
            location: point,
            grabPoint: point,
            wrist: point,
            palmLength: 0.1,
            pinchRatio: pinch,
            skeleton: []
        )
    }

    /// A reading the body placed on `side`.
    private func reading(at point: CGPoint, side: HandSide?) -> HandClassifier.Classification {
        var placed = reading(at: point)
        placed.side = side
        return placed
    }

    private let centre = CGPoint(x: 0.5, y: 0.5)

    // MARK: - Identity

    @Test func aHandKeepsItsIDFromFrameToFrame() {
        var tracker = HandIdentityTracker()

        let first = tracker.update(with: [reading(at: centre)], at: 0)
        let second = tracker.update(with: [reading(at: CGPoint(x: 0.52, y: 0.5))], at: 0.033)

        #expect(first.map(\.id) == [0])
        #expect(second.map(\.id) == [0])
    }

    @Test func twoHandsGetDifferentIDs() {
        var tracker = HandIdentityTracker()

        let hands = tracker.update(
            with: [reading(at: CGPoint(x: 0.2, y: 0.5)), reading(at: CGPoint(x: 0.8, y: 0.5))],
            at: 0
        )

        #expect(Set(hands.map(\.id)) == [0, 1])
    }

    // MARK: - Grace period

    /// Vision regularly drops a frame to motion blur. The hand must stay on
    /// screen, where it was, or the aura strobes and a grab can let go.
    @Test func aHandMissingForOneFrameIsStillPublished() {
        var tracker = HandIdentityTracker()
        _ = tracker.update(with: [reading(at: centre)], at: 0)

        let hands = tracker.update(with: [], at: 0.1)

        #expect(hands.map(\.id) == [0])
        #expect(hands.first?.cursorPosition == centre)
    }

    @Test func aHandMissingLongerThanTheGracePeriodGoesAway() {
        var tracker = HandIdentityTracker()
        _ = tracker.update(with: [reading(at: centre)], at: 0)

        let hands = tracker.update(with: [], at: tracker.gracePeriod + 0.1)

        #expect(hands.isEmpty)
    }

    /// Once a hand has been dropped, the next one seen is a new hand — it must
    /// not inherit an ID (and with it, whatever the old hand was holding).
    @Test func aHandSeenAgainAfterTheGracePeriodIsANewHand() {
        var tracker = HandIdentityTracker()
        _ = tracker.update(with: [reading(at: centre)], at: 0)
        _ = tracker.update(with: [], at: tracker.gracePeriod + 0.1)

        let hands = tracker.update(with: [reading(at: centre)], at: tracker.gracePeriod + 0.2)

        #expect(hands.map(\.id) == [1])
    }

    // MARK: - Smoothing

    /// The cursor moves only part of the way toward each new reading, which is
    /// what keeps Vision's jitter from sliding the hand off an ingredient.
    @Test func theCursorMovesPartWayTowardANewReading() {
        var tracker = HandIdentityTracker()
        _ = tracker.update(with: [reading(at: centre)], at: 0)

        let hands = tracker.update(with: [reading(at: CGPoint(x: 0.6, y: 0.5))], at: 0.033)

        let expectedX = 0.5 + 0.1 * tracker.cursorSmoothing
        let x = hands.first?.cursorPosition.x ?? 0
        #expect(abs(x - expectedX) < 0.0001)
    }

    // MARK: - Pinch

    /// One pinched frame is not a grab; a short run of them is.
    @Test func aPinchCommitsOnlyAfterSeveralFrames() {
        var tracker = HandIdentityTracker()

        let afterOne = tracker.update(with: [reading(at: centre, pinch: 0.1)], at: 0)
        _ = tracker.update(with: [reading(at: centre, pinch: 0.1)], at: 0.033)
        let afterThree = tracker.update(with: [reading(at: centre, pinch: 0.1)], at: 0.066)

        #expect(afterOne.first?.isClosedFist == false)
        #expect(afterThree.first?.isClosedFist == true)
    }

    /// A frame with no reading is no evidence either way: a grip already
    /// committed survives it instead of turning unknown.
    @Test func aGripSurvivesAFrameWithNoReading() {
        var tracker = HandIdentityTracker()
        for frame in 0..<3 {
            _ = tracker.update(with: [reading(at: centre, pinch: 0.1)], at: Double(frame) / 30)
        }

        let coasting = tracker.update(with: [], at: 0.1)

        #expect(coasting.first?.isClosedFist == true)
    }

    /// Coasting discards a half-built case for a change, so a grip still needs
    /// a full run of frames after the gap.
    @Test func aFrameWithNoReadingDiscardsUnfinishedEvidence() {
        var tracker = HandIdentityTracker()
        _ = tracker.update(with: [reading(at: centre, pinch: 0.1)], at: 0)
        _ = tracker.update(with: [reading(at: centre, pinch: 0.1)], at: 0.033)
        _ = tracker.update(with: [], at: 0.066)

        let afterGap = tracker.update(with: [reading(at: centre, pinch: 0.1)], at: 0.1)

        #expect(afterGap.first?.isClosedFist == false)
    }

    // MARK: - Continuation

    @Test func aReadingNextToATrackedHandContinuesIt() {
        var tracker = HandIdentityTracker()
        _ = tracker.update(with: [reading(at: centre)], at: 0)

        let nearby = CGPoint(x: centre.x + 0.05, y: centre.y)
        let farAway = CGPoint(x: 0.9, y: 0.9)
        let continuing = tracker.continuingIndices(of: [farAway, nearby], at: 0.033)

        #expect(continuing == [1])
    }

    @Test func aHandPastTheGracePeriodCannotBeContinued() {
        var tracker = HandIdentityTracker()
        _ = tracker.update(with: [reading(at: centre)], at: 0)

        let continuing = tracker.continuingIndices(of: [centre], at: tracker.gracePeriod + 0.1)

        #expect(continuing.isEmpty)
    }

    @Test func continuingReadingsComeNearestFirst() {
        let continuing = HandIdentityTracker.continuationIndices(
            of: [CGPoint(x: 0.58, y: 0.5), CGPoint(x: 0.51, y: 0.5)],
            lastLocations: [centre],
            radius: 0.1
        )

        #expect(continuing == [1, 0])
    }

    @Test func fPinchRequiresThreeExtendedSupportingFingers() {
        var tracker = HandIdentityTracker()
        let straight = finger()
        let curled = finger(curled: true)
        var hand = reading(at: centre, pinch: 0.2)
        hand.geometry = GestureGeometry(index: curled, middle: straight, ring: curled, little: straight)
        for frame in 0..<3 {
            let hands = tracker.update(with: [hand], grip: .fPinch, at: Double(frame) / 30)
            #expect(hands.first?.isClosedFist == false)
        }

        hand.geometry = GestureGeometry(index: curled, middle: straight, ring: straight, little: straight)
        _ = tracker.update(with: [hand], grip: .fPinch, at: 0.10)
        _ = tracker.update(with: [hand], grip: .fPinch, at: 0.13)
        let active = tracker.update(with: [hand], grip: .fPinch, at: 0.16)
        #expect(active.first?.isClosedFist == true)
    }

    /// People's middle finger tends to stay lower than the other two in an F
    /// sign, so F-Pinch counts a finger that is only mostly extended.
    @Test func fPinchAcceptsADroopingMiddleFinger() {
        var tracker = HandIdentityTracker()
        var hand = reading(at: centre, pinch: 0.2)
        hand.geometry = GestureGeometry(index: finger(curled: true), middle: droopingFinger(),
                                        ring: finger(), little: finger())

        var hands: [HandData] = []
        for frame in 0..<3 { hands = tracker.update(with: [hand], grip: .fPinch, at: Double(frame) / 30) }

        #expect(hands.first?.isClosedFist == true)
    }

    @Test func aDroopingFingerIsMostlyButNotFullyExtended() throws {
        let drooping = try #require(droopingFinger())

        #expect(drooping.isMostlyExtended)
        #expect(!drooping.isExtended)
    }

    private func finger(curled: Bool = false) -> GestureGeometry.Finger? {
        let joints = curled
            ? [CGPoint(x: 0, y: 1), CGPoint(x: 0, y: 1.3), CGPoint(x: 0.18, y: 1.32), CGPoint(x: 0.1, y: 1.05)]
            : [CGPoint(x: 0, y: 1), CGPoint(x: 0, y: 1.3), CGPoint(x: 0, y: 1.5), CGPoint(x: 0, y: 1.8)]
        return GestureGeometry.Finger(joints: joints, wrist: .zero, palmLength: 1)
    }

    /// Bent about 35° at the middle joint: past the open-hand threshold, within
    /// the F-Pinch one.
    private func droopingFinger() -> GestureGeometry.Finger? {
        let joints = [CGPoint(x: 0, y: 1), CGPoint(x: 0, y: 1.3), CGPoint(x: 0.115, y: 1.464), CGPoint(x: 0.258, y: 1.669)]
        return GestureGeometry.Finger(joints: joints, wrist: .zero, palmLength: 1)
    }

    // MARK: - Sides

    /// The body pose runs less often than the hand pose, so a frame without
    /// a body keeps the side the hand already had.
    @Test func aHandKeepsItsSideBetweenBodyPoses() {
        var tracker = HandIdentityTracker()

        _ = tracker.update(with: [reading(at: centre, side: .right)], at: 0)
        let unplaced = tracker.update(with: [reading(at: centre, side: nil)], at: 0.033)

        #expect(unplaced.map(\.side) == [.right])
    }

    /// A hand still remembering "left" gives way to the hand the body has
    /// just placed as the left one, so there are never two left hands.
    @Test func twoHandsNeverShareASide() {
        var tracker = HandIdentityTracker()
        let leftSpot = CGPoint(x: 0.3, y: 0.5)
        let rightSpot = CGPoint(x: 0.7, y: 0.5)
        _ = tracker.update(with: [reading(at: leftSpot, side: .left)], at: 0)

        let hands = tracker.update(
            with: [reading(at: leftSpot, side: nil), reading(at: rightSpot, side: .left)], at: 0.033
        )

        #expect(Set(hands.compactMap(\.side)) == [.left, .right])
        #expect(hands.first { $0.cursorPosition.x > 0.5 }?.side == .left)
    }
}
