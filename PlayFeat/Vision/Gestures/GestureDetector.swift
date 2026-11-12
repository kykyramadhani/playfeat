//
//  GestureDetector.swift
//  PlayFeat
//  Created by Owen Limantoro on 12/11/26.
//
//  Decides whether one hand is holding the selected grip, from a run of
//  frames rather than any single one. Each frame votes to make or let go of
//  the grip, and the state only flips once a short run of frames agrees, so a
//  single misread frame can't grab or drop anything.
//

import CoreGraphics
import Foundation

nonisolated struct GestureDetector {
    enum State: Equatable {
        /// The grip isn't being made.
        case neutral
        /// This frame can't say either way (a fingertip or finger wasn't seen).
        case uncertain
        /// The grip is being made.
        case active
    }

    /// What one frame says: whether the hand is making the grip, and whether
    /// it has let go. The two thresholds differ (hysteresis), so a hand right
    /// at the boundary doesn't flicker between states.
    struct Vote: Equatable {
        let makesGrip: Bool
        let releasesGrip: Bool
    }

    /// Why a frame couldn't vote.
    enum Uncertainty: Error, Equatable {
        case pinchNotMeasured
        case fingerShapesNotMeasured
        case indexFingerMissing
        case supportingFingerMissing
    }

    // MARK: - Tuning

    /// Pinch: the thumb-to-index gap, in palm lengths.
    static let pinchCloseRatio: CGFloat = 0.3
    static let pinchOpenRatio: CGFloat = 0.4
    /// F-Pinch closes tighter, since the raised fingers already make it
    /// deliberate.
    static let fPinchCloseRatio: CGFloat = 0.23
    static let fPinchOpenRatio: CGFloat = 0.35

    /// Agreeing frames, and time, needed before the state changes: about a
    /// tenth of a second at 30 fps, long enough to outlast a stray bad frame.
    static let framesToCommit = 3
    static let minimumCommitTime: TimeInterval = 0.05
    /// A longer gap between frames means the hand left and came back, so
    /// nothing from before it still counts.
    static let maximumFrameGap: TimeInterval = 0.15
    /// How long the grip survives frames that can't vote before it lets go.
    static let uncertainGripTimeout: TimeInterval = 0.25

    // MARK: - State

    private(set) var state = State.uncertain
    private var isActive = false
    private var lastFrame: TimeInterval?
    private var uncertainSince: TimeInterval?
    private var evidence = 0
    private var evidenceSince: TimeInterval = 0

    // MARK: - Recording

    /// Feeds one frame's reading of this hand in.
    mutating func record(_ reading: HandClassifier.Classification, grip: GripGesture, at now: TimeInterval) {
        forgetIfHandWasGone(at: now)
        dropGripIfUncertainTooLong(at: now)
        lastFrame = now

        do {
            let vote = try Self.vote(for: reading, grip: grip)
            uncertainSince = nil
            count(vote, at: now)
        } catch {
            markUncertain(because: error, at: now)
        }
    }

    /// A frame with no reading for this hand at all (it is coasting).
    ///
    /// That is no evidence either way, so the state holds: a grip survives a
    /// frame Vision dropped. Only the half-built case for a change is
    /// discarded, so it can't resume against a newer, contradicting run of
    /// frames. Counts as a frame for the gap rule in `record`.
    mutating func coast(at now: TimeInterval) {
        lastFrame = now
        evidence = 0
    }

    // MARK: - Voting

    /// How one reading votes for `grip`. Throws when the reading is missing
    /// something the grip is judged by.
    static func vote(
        for reading: HandClassifier.Classification,
        grip: GripGesture
    ) throws(Uncertainty) -> Vote {
        guard let ratio = reading.pinchRatio else { throw .pinchNotMeasured }

        switch grip {
        case .pinch:
            return Vote(makesGrip: ratio <= pinchCloseRatio, releasesGrip: ratio >= pinchOpenRatio)

        case .fPinch:
            guard let geometry = reading.geometry else { throw .fingerShapesNotMeasured }
            guard let index = geometry.index else { throw .indexFingerMissing }
            guard geometry.fingers.count == 4 else { throw .supportingFingerMissing }

            let raised = geometry.supportingMostlyExtendedCount
            return Vote(
                makesGrip: ratio <= fPinchCloseRatio && !index.isExtended && raised == 3,
                releasesGrip: ratio >= fPinchOpenRatio || raised <= 1
            )
        }
    }

    private mutating func count(_ vote: Vote, at now: TimeInterval) {
        if isActive ? vote.releasesGrip : vote.makesGrip {
            if evidence == 0 { evidenceSince = now }
            evidence += 1
            if evidence >= Self.framesToCommit, now - evidenceSince >= Self.minimumCommitTime {
                isActive.toggle()
                evidence = 0
            }
        } else {
            evidence = 0
        }
        state = isActive ? .active : .neutral
    }

    // MARK: - Timing rules

    private mutating func forgetIfHandWasGone(at now: TimeInterval) {
        guard let lastFrame, now - lastFrame > Self.maximumFrameGap else { return }
        #if DEBUG
        print("[gesture] detector reset: \(Int((now - lastFrame) * 1000)) ms since the last frame")
        #endif
        self = GestureDetector()
    }

    private mutating func dropGripIfUncertainTooLong(at now: TimeInterval) {
        guard let uncertainSince, now - uncertainSince >= Self.uncertainGripTimeout else { return }
        #if DEBUG
        print("[gesture] grip dropped: uncertain for \(Int((now - uncertainSince) * 1000)) ms")
        #endif
        isActive = false
    }

    private mutating func markUncertain(because reason: Uncertainty, at now: TimeInterval) {
        #if DEBUG
        print("[gesture] uncertain: \(reason)")
        #endif
        state = .uncertain
        evidence = 0
        if uncertainSince == nil { uncertainSince = now }
    }
}
