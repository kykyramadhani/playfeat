//
//  HandClassifier.swift
//  PlayFeat
//
//  Created by Owen Limantoro on 08/10/26.
//
//  Reads one Vision hand observation: where the palm is, where the wrist is,
//  how big the hand looks, how far apart the thumb and index fingertips are
//  (the pinch that grabs), where the grip holds things, and, for F-Pinch, the
//  shape of each finger. Pure, so the maths can be tested without a camera.
//

import Vision
import CoreGraphics

/// A caseless enum: a namespace for functions, never instantiated.
/// `nonisolated` so frames can be classified on the camera's background queue.
nonisolated enum HandClassifier {
    /// What one Vision hand observation says about that hand.
    struct Classification {
        /// Palm centre, normalized Vision space.
        let location: CGPoint
        /// Where the pinch holds things, normalized Vision space. Picks which
        /// bubble a grab takes (see `grabPoint(palmCentre:thumbTip:indexTip:)`).
        let grabPoint: CGPoint
        /// The hand's own wrist joint. Matched against the *body* detector's
        /// wrists to work out whose arm this hand is on.
        let wrist: CGPoint
        /// Wrist → knuckles, in metric space (see `metricPoint`). Doubles as
        /// a distance-from-camera cue: the same hand twice as far away
        /// measures half as long.
        let palmLength: CGFloat
        /// Thumb-tip to index-tip gap, in palm lengths. Nil when either tip
        /// was missing this frame: the grip then can't be judged either way.
        let pinchRatio: CGFloat?
        let skeleton: [[CGPoint]]
        /// Each finger's shape. Only measured for grips judged from them
        /// (see `GripGesture.usesFingerShapes`).
        var geometry: GestureGeometry? = nil
        /// Which of the player's hands this is, placed from the body pose
        /// (see `HandSideAssigner`); nil when the body couldn't tell.
        var side: HandSide? = nil
    }

    enum ClassificationError: Error {
        case noReliableWrist
        case noReliablePalm
    }
    
    private typealias JointName = VNHumanHandPoseObservation.JointName

    /// Palm width (index knuckle → little knuckle) over palm length, for a
    /// palm facing the camera. Outside this the hand is turned edge-on or
    /// tilted, finger shapes come out foreshortened, and none are measured.
    private static let facingPalmWidthRatios: ClosedRange<CGFloat> = 0.30...1.25

    /// Joint chains used both for the skeleton overlay and for the palm
    /// measurements below — wrist first, fingertip last.
    private static let fingerChains: [[JointName]] = [
        [.wrist, .thumbCMC, .thumbMP, .thumbIP, .thumbTip],
        [.wrist, .indexMCP, .indexPIP, .indexDIP, .indexTip],
        [.wrist, .middleMCP, .middlePIP, .middleDIP, .middleTip],
        [.wrist, .ringMCP, .ringPIP, .ringDIP, .ringTip],
        [.wrist, .littleMCP, .littlePIP, .littleDIP, .littleTip]
    ]
    
    /// The gap between thumb tip and index-finger tip, in palm lengths —
    /// small means the two are pinched together, which is the grab gesture.
    ///
    /// Nil when either tip is missing, or the palm couldn't be measured: the
    /// caller reads that as "not grabbing", so a hand whose thumb drops out of
    /// tracking opens rather than clamping shut on whatever is nearby.
    static func pinchRatio(
        thumbTip: CGPoint?,
        indexTip: CGPoint?,
        palmLength: CGFloat
    ) -> CGFloat? {
        guard palmLength > 0, let thumbTip, let indexTip else { return nil }
        return thumbTip.distance(to: indexTip) / palmLength
    }

    /// Width ÷ height of the camera frame: the factor `metricPoint` scales x by.
    static func aspectRatio(of bufferSize: CGSize) -> CGFloat {
        bufferSize.height > 0 ? bufferSize.width / bufferSize.height : 1
    }

    /// A normalized Vision point stretched so both axes share one unit.
    ///
    /// Vision normalizes x over the frame's width and y over its height, so in
    /// a landscape frame the same gap measures shorter sideways than upright.
    /// Scaling x by the aspect ratio puts both axes in frame heights, so
    /// distances and angles stop depending on how the hand is turned. Only
    /// measurements use it; positions handed on stay normalized.
    static func metricPoint(_ point: CGPoint, aspectRatio: CGFloat) -> CGPoint {
        CGPoint(x: point.x * aspectRatio, y: point.y)
    }

    /// Where a pinch holds what it picks up: midway between the thumb and
    /// index fingertips, or the palm centre while either tip isn't seen.
    static func grabPoint(palmCentre: CGPoint, thumbTip: CGPoint?, indexTip: CGPoint?) -> CGPoint {
        guard let thumbTip, let indexTip else { return palmCentre }
        return thumbTip.midpoint(with: indexTip)
    }

    static func classify(
        _ observation: VNHumanHandPoseObservation,
        jointConfidenceThreshold: Float,
        bufferSize: CGSize,
        grip: GripGesture
    ) throws -> Classification {
        let joints = try observation.recognizedPoints(.all).compactMapValues { joint -> CGPoint? in
            guard joint.confidence >= jointConfidenceThreshold else { return nil }
            return CGPoint(x: joint.location.x, y: joint.location.y)
        }
        func point(_ name: JointName) -> CGPoint? { joints[name] }

        guard let wrist = point(.wrist) else { throw ClassificationError.noReliableWrist }

        let skeleton = fingerChains.map { $0.compactMap(point) }

        // Track the palm centre (wrist + knuckles) rather than including the
        // fingertips: the palm barely moves when the hand opens and closes, so
        // the cursor stays put at the exact moment the player pinches to grab.
        let knuckles: [JointName] = [.middleMCP, .indexMCP, .ringMCP, .littleMCP]
        let knucklePoints = knuckles.compactMap(point)
        let palmPoints = [wrist] + knucklePoints
        let sum = palmPoints.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        let centre = CGPoint(x: sum.x / CGFloat(palmPoints.count), y: sum.y / CGFloat(palmPoints.count))

        // Every measurement from here on is taken in metric space, so the
        // pinch and the finger shapes share one palm length and one unit.
        let aspectRatio = Self.aspectRatio(of: bufferSize)
        func metric(_ point: CGPoint) -> CGPoint { metricPoint(point, aspectRatio: aspectRatio) }

        // Palm length = wrist → knuckles, the scale reference every other
        // measurement is divided by. Taking the largest available MCP keeps a
        // sane value when the middle knuckle briefly drops out.
        guard let palmLength = knucklePoints.map({ metric(wrist).distance(to: metric($0)) }).max(),
              palmLength > 0 else {
            throw ClassificationError.noReliablePalm
        }

        let pinch = pinchRatio(
            thumbTip: point(.thumbTip).map(metric),
            indexTip: point(.indexTip).map(metric),
            palmLength: palmLength
        )

        return Classification(
            location: centre,
            grabPoint: grabPoint(palmCentre: centre, thumbTip: point(.thumbTip), indexTip: point(.indexTip)),
            wrist: wrist,
            palmLength: palmLength,
            pinchRatio: pinch,
            skeleton: skeleton,
            geometry: grip.usesFingerShapes
                ? fingerShapes(of: joints, palmLength: palmLength, aspectRatio: aspectRatio)
                : nil
        )
    }

    /// The shape of the four fingers, or nil when the palm isn't facing the
    /// camera well enough to judge them.
    private static func fingerShapes(
        of joints: [JointName: CGPoint],
        palmLength: CGFloat,
        aspectRatio: CGFloat
    ) -> GestureGeometry? {
        func metric(_ name: JointName) -> CGPoint? {
            joints[name].map { metricPoint($0, aspectRatio: aspectRatio) }
        }

        guard let wrist = metric(.wrist), let indexBase = metric(.indexMCP), let littleBase = metric(.littleMCP) else {
            #if DEBUG
            print("[gesture] geometry nil: index or little knuckle below the confidence threshold")
            #endif
            return nil
        }

        let widthRatio = indexBase.distance(to: littleBase) / palmLength
        guard facingPalmWidthRatios.contains(widthRatio) else {
            #if DEBUG
            print("[gesture] geometry nil: palm ratio \(String(format: "%.2f", widthRatio))"
                  + " outside 0.30…1.25 (hand turned edge-on or tilted)")
            #endif
            return nil
        }

        let fingers = fingerChains.dropFirst().map { chain in
            GestureGeometry.Finger(joints: chain.dropFirst().compactMap(metric), wrist: wrist, palmLength: palmLength)
        }
        return GestureGeometry(index: fingers[0], middle: fingers[1], ring: fingers[2], little: fingers[3])
    }
}
