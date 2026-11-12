//
//  GestureGeometry.swift
//  PlayFeat
//  Created by Owen Limantoro on 12/11/26.
//
//  The shape of each finger in one hand reading: how straight it is and how
//  far it reaches. F-Pinch is judged from these, on top of the pinch itself.
//

import CoreGraphics
import Foundation

nonisolated struct GestureGeometry: Equatable, Sendable {
    /// One finger, measured from its four joints (knuckle → tip) in metric
    /// space (see `HandClassifier.metricPoint`).
    struct Finger: Equatable, Sendable {
        /// Cosine of the bend at the middle joint: 1 is dead straight.
        private let alignment: CGFloat
        /// Knuckle-to-tip distance over the finger's own length: 1 when the
        /// finger is fully stretched, lower the more it curls.
        private let reach: CGFloat

        private static let extendedAlignment = CGFloat(cos(0.40))
        private static let extendedReach: CGFloat = 0.83

        /// How much of the extended thresholds a finger needs to count as
        /// mostly extended: 20% below them.
        private static let droopAllowance: CGFloat = 0.7

        var isExtended: Bool { alignment >= Self.extendedAlignment && reach >= Self.extendedReach }

        /// Extended, allowing for a finger that droops a little. Held in an F
        /// sign, people's middle finger often stays lower than the ring and
        /// little fingers, and would fail the open-hand threshold.
        var isMostlyExtended: Bool {
            alignment >= Self.extendedAlignment * Self.droopAllowance
                && reach >= Self.extendedReach * Self.droopAllowance
        }

        /// Nil when the joints are too bunched up to measure, which is what a
        /// finger pointing at the camera looks like.
        init?(joints: [CGPoint], wrist: CGPoint, palmLength: CGFloat) {
            guard joints.count == 4 else { return nil }
            let base = joints[0], pip = joints[1], dip = joints[2], tip = joints[3]
            let proximal = base.distance(to: pip)
            let middle = pip.distance(to: dip)
            let distal = dip.distance(to: tip)
            let axis = wrist.distance(to: base)
            guard min(proximal, middle, distal) >= palmLength * 0.035,
                  axis >= palmLength * 0.35 else { return nil }

            let dot = (pip.x - base.x) * (dip.x - pip.x) + (pip.y - base.y) * (dip.y - pip.y)
            alignment = dot / (proximal * middle)
            reach = base.distance(to: tip) / (proximal + middle + distal)

            #if DEBUG
            print("[gesture] finger \(joints.map { String(format: "(%.2f,%.2f)", $0.x, $0.y) }.joined(separator: " → "))"
                  + " alignment \(String(format: "%.2f", alignment))"
                  + " reach \(String(format: "%.2f", reach))")
            #endif
        }
    }

    let index: Finger?
    let middle: Finger?
    let ring: Finger?
    let little: Finger?

    /// The fingers held up in an F sign, beside the pinching index.
    private var supporting: [Finger] { [middle, ring, little].compactMap { $0 } }
    var fingers: [Finger] { [index, middle, ring, little].compactMap { $0 } }
    var supportingMostlyExtendedCount: Int { supporting.filter(\.isMostlyExtended).count }
}
