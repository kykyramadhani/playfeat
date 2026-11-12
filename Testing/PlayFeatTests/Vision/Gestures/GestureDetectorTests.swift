//
//  GestureDetectorTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 12/11/26.
//
//  How one frame votes for a grip, and how the detector treats frames that
//  can't vote. The multi-frame commit is covered in HandIdentityTrackerTests.
//

import Testing
import CoreGraphics
@testable import PlayFeat

struct GestureDetectorTests {

    private func reading(pinch: CGFloat?) -> HandClassifier.Classification {
        HandClassifier.Classification(
            location: .zero,
            grabPoint: .zero,
            wrist: .zero,
            palmLength: 0.1,
            pinchRatio: pinch,
            skeleton: []
        )
    }

    // MARK: - Voting

    /// Between the two thresholds the frame neither makes nor lets go of the
    /// grip, so a hand at the boundary keeps its state.
    @Test func aGapBetweenTheThresholdsVotesNeitherWay() throws {
        let vote = try GestureDetector.vote(for: reading(pinch: 0.4), grip: .pinch)

        #expect(vote == GestureDetector.Vote(makesGrip: false, releasesGrip: false))
    }

    @Test func aMissingFingertipCannotVote() {
        #expect(throws: GestureDetector.Uncertainty.pinchNotMeasured) {
            try GestureDetector.vote(for: reading(pinch: nil), grip: .pinch)
        }
    }

    @Test func fPinchCannotVoteWithoutFingerShapes() {
        #expect(throws: GestureDetector.Uncertainty.fingerShapesNotMeasured) {
            try GestureDetector.vote(for: reading(pinch: 0.1), grip: .fPinch)
        }
    }

    // MARK: - Recording

    @Test func aFrameThatCannotVoteReadsAsUncertain() {
        var detector = GestureDetector()

        detector.record(reading(pinch: nil), grip: .pinch, at: 0)

        #expect(detector.state == .uncertain)
    }

    /// A pinch whose fingertips stay unreadable lets go, rather than holding
    /// an ingredient forever on a hand that may have opened.
    @Test func aGripLetsGoAfterStayingUncertain() {
        var detector = activePinch()
        let lastPinch = 0.066
        for frame in 1...10 {
            detector.record(reading(pinch: nil), grip: .pinch, at: lastPinch + Double(frame) / 30)
        }

        detector.record(reading(pinch: 0.4), grip: .pinch, at: lastPinch + 11.0 / 30)

        #expect(detector.state == .neutral)
    }

    @Test func aGripSurvivesABriefUncertainSpell() {
        var detector = activePinch()
        detector.record(reading(pinch: nil), grip: .pinch, at: 0.1)

        detector.record(reading(pinch: 0.4), grip: .pinch, at: 0.133)

        #expect(detector.state == .active)
    }

    private func activePinch() -> GestureDetector {
        var detector = GestureDetector()
        for frame in 0..<3 { detector.record(reading(pinch: 0.1), grip: .pinch, at: Double(frame) * 0.033) }
        return detector
    }
}
