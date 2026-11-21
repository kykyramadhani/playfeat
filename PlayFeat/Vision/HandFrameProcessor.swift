//
//  HandFrameProcessor.swift
//  PlayFeat
//
//  Everything done to one camera frame, in order:
//
//    1. Vision: hand pose (every frame) + body pose (every Nth frame)
//    2. Body: who the player is (PlayerSelector: the seat frame, then the lock)
//    3. HandClassifier: palm, wrist and pinch gap for each hand Vision saw
//    4. Body filter: keep only the player's hands, for the current input mode
//    5. HandIdentityTracker: stable IDs, smoothing, pinch state, coasting
//
//  Runs on the camera's video queue, so it is `nonisolated` and owns all of
//  its state — nothing here is touched from the main thread. The result of
//  each frame goes back as one `Output`, which HandPoseManager publishes on
//  the main thread.
//

import CoreGraphics
import QuartzCore
import Vision

/// `@unchecked Sendable`: handed to the camera's frame callback, and only
/// ever used from the video queue, one frame at a time.
nonisolated final class HandFrameProcessor: @unchecked Sendable {

    /// What one frame produced.
    struct Output {
        /// Size of the frame Vision read, after rotation.
        let bufferSize: CGSize
        /// The player's body (see PlayerSelector), nil when nobody is tracked.
        let playerBody: HumanBodyPoseManager.BodyCandidate?
        /// The player's hands, with stable IDs, including coasting ones.
        let hands: [HandData]
    }

    // MARK: - Configuration
    //
    // Tuning knobs. Set them before the camera starts: after that they are
    // read on the video queue.

    /// How many hands to actually play with — one player, two hands.
    var maximumHandCount = 2

    /// How many hands Vision may report before the single-player filter runs.
    var handCandidateLimit = 4 {
        didSet { handPoseRequest.maximumHandCount = handCandidateLimit }
    }

    /// Whether hands are gated on the body they are attached to.
    var tracksSinglePlayer = true

    /// Minimum Vision joint confidence to trust a point.
    var jointConfidenceThreshold: Float = 0.25 {
        didSet { bodyPoseManager.jointConfidenceThreshold = jointConfidenceThreshold }
    }

    /// Run the body detector on one frame in this many, reusing the last
    /// result in between.
    var bodyPoseFrameInterval: Int {
        get { bodyPoseManager.bodyPoseFrameInterval }
        set { bodyPoseManager.bodyPoseFrameInterval = newValue }
    }

    /// How far a hand's own wrist may sit from a body's wrist and still count
    /// as that body's, as a multiple of that body's shoulder span.
    var wristMatchTolerance: CGFloat {
        get { bodyPoseManager.wristMatchTolerance }
        set { bodyPoseManager.wristMatchTolerance = newValue }
    }

    // MARK: - State (video queue only)

    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private let bodyPoseManager = HumanBodyPoseManager()

    /// Keeps each hand's ID, smoothed cursor and pinch state between frames.
    private var identityTracker = HandIdentityTracker()

    /// The last player body, kept for frames where body pose doesn't run or
    /// Vision fails.
    private var playerBody: HumanBodyPoseManager.BodyCandidate?

    /// Who the player is. Changed only through the methods below, which
    /// HandPoseManager calls on the video queue like everything else here.
    private var selector = PlayerSelector()

    // MARK: - Player selection (video queue only)

    /// Until the lock, only someone in `zone` can be the player.
    func setPlayerZone(_ zone: PlayerSelector.Zone) {
        selector.zone = zone
    }

    /// From now on only `body`'s owner is the player, followed as they move,
    /// and each of their hands keeps the side it was calibrated with.
    func lockOntoPlayer(_ body: HumanBodyPoseManager.BodyCandidate) {
        selector.lock(onto: body)
        identityTracker.keepsHandSides = true
    }

    /// Forgets the locked player and the zone, ready for the next calibration.
    func releasePlayer() {
        selector.reset()
        identityTracker.keepsHandSides = false
    }

    /// A nil generation skips Vision entirely. Updated on the video queue
    /// so each frame belongs to the tracking session that processed it.
    var frameGeneration: UInt?

    init() {
        handPoseRequest.maximumHandCount = handCandidateLimit
    }

    // MARK: - One frame

    func process(_ pixelBuffer: CVPixelBuffer) -> Output {
        // Dimensions come from the delivered buffer, so they already account
        // for whatever rotation the connection is applying.
        let bufferSize = CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
        let grip = GripGesture.stored()

        // One handler for whatever runs this frame: the image is decoded once.
        let runsBodyPose = bodyPoseManager.shouldRunBodyPose(tracksSinglePlayer: tracksSinglePlayer)

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        do {
            try handler.perform(runsBodyPose ? [handPoseRequest, bodyPoseManager.bodyPoseRequest]
                                             : [handPoseRequest])
        } catch {
            return output(tracking: [], grip: grip, bufferSize: bufferSize)
        }

        // Everyone else in the room is ignored from here on. Resolved before
        // the hand guards below, so the skeleton keeps up with the player even
        // in the frames where their hands are down or out of shot — otherwise
        // the last body drawn would stay frozen on screen.
        if runsBodyPose {
            _ = bodyPoseManager.processObservations(bodyPoseManager.bodyPoseRequest.results)
        }
        let bodies = tracksSinglePlayer ? bodyPoseManager.lastBodies : []

        // Only the player's body, so what is drawn is always exactly who the
        // game is listening to.
        let player = selector.trackPlayer(in: bodies, bufferSize: bufferSize)
        playerBody = player.map { bodies[$0] }

        let observations = handPoseRequest.results ?? []
        let classifications = observations.compactMap { observation -> HandClassifier.Classification? in
            do {
                return try HandClassifier.classify(observation, jointConfidenceThreshold: jointConfidenceThreshold,
                                                   bufferSize: bufferSize, grip: grip)
            } catch {
                #if DEBUG
                print("[gesture] hand dropped: classify failed (\(error))")
                #endif
                return nil
            }
        }
        guard !classifications.isEmpty else {
            return output(tracking: [], grip: grip, bufferSize: bufferSize)
        }

        // No body, no hands. A hand is only the player's if it can be tied to
        // a visible shoulder, so a torso out of frame means nothing is tracked
        // — the same rule the seat check enforces before the game even starts.
        guard let player else {
            #if DEBUG
            print("[gesture] \(classifications.count) hand(s) dropped: no player body")
            #endif
            return output(tracking: [], grip: grip, bufferSize: bufferSize)
        }

        let keep = playerHandIndices(of: classifications, bodies: bodies, player: player)

        #if DEBUG
        if keep.count < classifications.count {
            print("[gesture] \(classifications.count - keep.count) hand(s) dropped by the body-wrist match"
                  + " (body pose \(runsBodyPose ? "from this frame" : "from an earlier frame"))")
        }
        #endif

        return output(tracking: keep.map { classifications[$0] }, grip: grip, bufferSize: bufferSize)
    }

    /// Which of this frame's hands are the player's, up to the hand limit.
    ///
    /// The body check picks a hand up; carrying on from a tracked hand keeps
    /// it. The body's wrist can be a few frames stale, so on its own it keeps
    /// rejecting a hand that is moving fast.
    private func playerHandIndices(
        of classifications: [HandClassifier.Classification],
        bodies: [HumanBodyPoseManager.BodyCandidate],
        player: Int
    ) -> [Int] {
        let mode = HandInputModeSetting.stored()
        let limit = min(maximumHandCount, mode.handCount)

        let bodyMatched = HumanBodyPoseManager.playerHandIndices(
            handWrists: classifications.map(\.wrist),
            bodies: bodies,
            player: player,
            wristTolerance: wristMatchTolerance,
            limit: limit,
            mode: mode
        )
        let continuing = identityTracker
            .continuingIndices(of: classifications.map(\.location), at: CACurrentMediaTime())
            .filter { !bodyMatched.contains($0) }
        let keep = Array((bodyMatched + continuing).prefix(limit))

        #if DEBUG
        let rescued = keep.count - bodyMatched.count
        if rescued > 0 { print("[gesture] \(rescued) hand(s) failed the body-wrist match, kept as continuing") }
        #endif

        return keep
    }

    /// The frame's output from the player's hands read in it: an empty list
    /// when Vision found nothing usable.
    ///
    /// Empty frames go through the tracker too, so they run the same coasting
    /// rule: anything still inside the grace period keeps being published at
    /// its last known position, and only a hand missing longer than that goes
    /// away. Blanking the list outright is what used to make a single dropped
    /// frame kill the aura.
    private func output(
        tracking readings: [HandClassifier.Classification],
        grip: GripGesture,
        bufferSize: CGSize
    ) -> Output {
        let hands = identityTracker.update(with: readings, grip: grip, at: CACurrentMediaTime())
        return Output(bufferSize: bufferSize, playerBody: playerBody, hands: hands)
    }
}
