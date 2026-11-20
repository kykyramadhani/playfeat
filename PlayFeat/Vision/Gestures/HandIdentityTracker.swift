//
//  HandIdentityTracker.swift
//  PlayFeat
//
//  Turns each frame's hand readings into hands with stable IDs. Vision
//  reports hands in no particular order, so this matches every reading to the
//  hand it most likely continues, smooths its cursor, keeps its grip state,
//  and lets a hand coast through a few dropped frames instead of vanishing.
//
//  Pure — readings and a timestamp in, hands out — so the whole thing can be
//  tested by feeding it made-up frames, without a camera.
//

// Possible Changes
// 1. There are possiblePinch/possibleApart states that are used to smooth out state transitions. 
//
//

import CoreGraphics
import Foundation
import Vision

/// `nonisolated` so it can run on the camera's background queue: it is a plain
/// value with no shared state.
nonisolated struct HandIdentityTracker {
    // MARK: - Tuning
    //
    // `var` on purpose: hand size, camera distance and lighting all shift
    // these, so they are tuning knobs, not constants.

    /// Exponential smoothing applied to each cursor (0 = frozen, 1 = raw).
    var cursorSmoothing: CGFloat = 0.5

    /// How far (in normalized units) a hand may travel between frames and still
    /// be considered the same hand.
    var matchRadius: CGFloat = 0.45

    /// How long a hand's trajectory survives after Vision stops reporting it.
    var gracePeriod: TimeInterval = 0.35

    /// How close (in normalized units) a reading must be to where a tracked
    /// hand was last seen to count as that hand carrying on, which keeps it
    /// even when the body check rejects it. Much tighter than `matchRadius`,
    /// so a bystander's hand can't take over a track from across the frame.
    var continuationRadius: CGFloat = 0.1

    /// Set once calibration has picked the player. From then on each hand
    /// keeps the side (left or right) it already has: Vision's guess flips
    /// now and then, and the drawn hand would flip with it. A hand that is
    /// lost and comes back gets a new ID, so its side is read afresh.
    var keepsHandSides = false

    // MARK: - State

    /// One hand as remembered between frames.
    private struct TrackedHand {
        let id: Int
        var smoothed: CGPoint
        /// Raw palm centre of the last reading. Continuation is judged from
        /// here, not from `smoothed`, which trails a fast-moving hand.
        var location: CGPoint
        /// Raw grab point of the last reading (see `HandData.grabPoint`).
        var grabPoint: CGPoint
        /// Evidence-based grip state — see `GestureDetector`.
        var gesture = GestureDetector()
        /// Last skeleton Vision gave for this hand. Kept so a hand that is
        /// coasting through a dropped frame can still be drawn where it was,
        /// rather than blinking out.
        var skeleton: [[CGPoint]]
        var chirality: VNChirality = .unknown
        /// Last time Vision actually reported this hand; drives the grace period.
        var lastSeen: TimeInterval

        var published: HandData {
            HandData(
                id: id,
                cursorPosition: smoothed,
                grabPoint: grabPoint,
                isOpenHand: gesture.state == .neutral,
                isClosedFist: gesture.state == .active,
                skeleton: skeleton,
                chirality: chirality
            )
        }
    }

    private var tracked: [TrackedHand] = []
    private var nextHandID = 0
    /// The grip the detectors were last fed. Switching grips starts every
    /// hand's detector afresh, so evidence for one grip can't count for another.
    private var currentGrip = GripGesture.defaultGesture

    // MARK: - Update

    /// Matches this frame's readings to the hands already being tracked and
    /// returns every hand to publish, including ones coasting through a
    /// dropped frame. Pass an empty array for a frame where Vision saw nothing.
    ///
    /// Vision hands back observations in no particular order, so without the
    /// matching the two hands would trade identities at random — and with them,
    /// whatever each was dragging.
    mutating func update(
        with readings: [HandClassifier.Classification],
        grip: GripGesture = .defaultGesture,
        at now: TimeInterval
    ) -> [HandData] {
        tracked.removeAll { now - $0.lastSeen > gracePeriod }
        restartDetectorsIfGripChanged(to: grip)

        let assignments = Self.matchAssignments(
            newPositions: readings.map(\.location),
            previousPositions: tracked.map(\.smoothed),
            radius: matchRadius
        )

        var stillTracked: [TrackedHand] = []

        for (index, reading) in readings.enumerated() {
            var hand: TrackedHand

            // Check if this reading continues a previously tracked hand, or is a new hand.
            if let previous = assignments[index] {
                hand = tracked[previous]
            } else {
                hand = TrackedHand(id: nextHandID, smoothed: reading.location,
                                   location: reading.location, grabPoint: reading.grabPoint,
                                   skeleton: reading.skeleton, lastSeen: now)
                #if DEBUG
                print("[gesture] hand \(nextHandID) is new: no tracked hand within the match radius,"
                      + " so its detector starts from scratch")
                #endif
                nextHandID += 1
            }
            hand.lastSeen = now
            hand.location = reading.location
            hand.grabPoint = reading.grabPoint
            hand.skeleton = reading.skeleton
            // An unreadable frame must not undo this hand's last known
            // orientation, and after calibration a known one stays put.
            if reading.chirality != .unknown, hand.chirality == .unknown || !keepsHandSides {
                hand.chirality = reading.chirality
            }

            // Smooth the cursor: Vision's per-frame jitter is easily 20–30pt on
            // screen, enough to slide off an ingredient mid-grab.
            hand.smoothed = CGPoint(
                x: hand.smoothed.x + (reading.location.x - hand.smoothed.x) * cursorSmoothing,
                y: hand.smoothed.y + (reading.location.y - hand.smoothed.y) * cursorSmoothing
            )

            // Evidence-based, and per hand, so neither one bad frame nor the
            // other hand can flip this one's state.
            hand.gesture.record(reading, grip: grip, at: now)

            stillTracked.append(hand)
        }

        // Hands Vision didn't report this frame keep *coasting*: they stay
        // tracked and stay published, sitting at their last known position,
        // until the grace period lapses.
        //
        // Publishing them is the point. Reporting only what Vision saw this
        // exact frame is what made the aura strobe — hand pose regularly drops
        // a frame to motion blur or a turned palm, and every one of those was
        // being handed downstream as "the hand is gone".
        let matched = Set(assignments.compactMap { $0 })
        for (index, previous) in tracked.enumerated() where !matched.contains(index) {
            var coasting = previous
            #if DEBUG
            print("[gesture] hand \(previous.id) coasting: no reading this frame, keeping its grip state")
            #endif
            // A frame with no reading is no evidence either way: the grip
            // holds, and only a half-built case for a change is discarded.
            coasting.gesture.coast(at: now)
            stillTracked.append(coasting)
        }

        tracked = stillTracked
        return stillTracked.map(\.published)
    }

    private mutating func restartDetectorsIfGripChanged(to grip: GripGesture) {
        guard grip != currentGrip else { return }
        for index in tracked.indices { tracked[index].gesture = GestureDetector() }
        currentGrip = grip
    }

    // MARK: - Continuation

    /// Indices of the `locations` that carry on a hand already being tracked,
    /// nearest first.
    ///
    /// The body check only gets a fresh body pose every few frames, so a
    /// fast-moving hand regularly outruns the player's stored wrist and is
    /// rejected, then coasts and freezes mid-gesture. Keeping any reading that
    /// picks up right where a tracked hand left off means the body check is
    /// only needed to pick a hand up, not to keep it.
    func continuingIndices(of locations: [CGPoint], at now: TimeInterval) -> [Int] {
        let current = tracked.filter { now - $0.lastSeen <= gracePeriod }
        return Self.continuationIndices(of: locations, lastLocations: current.map(\.location),
                                        radius: continuationRadius)
    }

    /// Pure core of `continuingIndices`, so it can be tested on its own.
    static func continuationIndices(of locations: [CGPoint], lastLocations: [CGPoint], radius: CGFloat) -> [Int] {
        let nearby: [(index: Int, distance: CGFloat)] = locations.indices.compactMap { index in
            guard let nearest = lastLocations.map({ $0.distance(to: locations[index]) }).min(),
                  nearest <= radius else { return nil }
            return (index, nearest)
        }
        return nearby.sorted { $0.distance < $1.distance }.map(\.index)
    }

    // MARK: - Matching

    /// For each freshly detected hand position, the index of the previously
    /// tracked hand it continues — or nil when it's a new hand.
    ///
    /// Greedy nearest-neighbour, each previous hand claimable once. This is
    /// what keeps `HandData.id` attached to the same physical hand: Vision
    /// hands back its observations in no guaranteed order, so matching by
    /// array position would let the two hands trade identities between frames,
    /// and each would inherit whatever the other was dragging.
    static func matchAssignments(
        newPositions: [CGPoint],
        previousPositions: [CGPoint],
        radius: CGFloat
    ) -> [Int?] {
        var claimed = Set<Int>()
        var assignments = [Int?](repeating: nil, count: newPositions.count)

        for (index, position) in newPositions.enumerated() {
            var best: Int?
            var bestDistance = radius
            for (candidate, previous) in previousPositions.enumerated() where !claimed.contains(candidate) {
                let distance = position.distance(to: previous)
                if distance < bestDistance {
                    bestDistance = distance
                    best = candidate
                }
            }
            if let best {
                claimed.insert(best)
                assignments[index] = best
            }
        }
        return assignments
    }
}
