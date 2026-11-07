//
//  FallMotion.swift
//  PlayFeat
//  Created by kyky on 07/11/26.
//
//  How fast released ingredients fall and bubbles drift, in kitchen heights
//  per second (KH/s) so the feel is the same on every iPad. 1 KH is the
//  distance from the top of the kitchen to the bottom edge of the screen.
//

import CoreGraphics
import Foundation

nonisolated struct FallMotion {
    /// KH/s = multiplier x 1.25, so 1.0x crosses the kitchen in 0.8 s.
    static let khPerSecondPerMultiplier = 1.25
    /// A released item reaches full speed after this long, then stays there.
    /// No open-ended acceleration, so a catch stays predictable.
    static let rampDuration: TimeInterval = 0.2

    let gravity: LevelData.Gravity
    /// 1 KH in points on this device.
    let kitchenHeight: CGFloat

    var fallSpeedKHPerSecond: Double {
        gravity.multiplier * Self.khPerSecondPerMultiplier
    }

    /// Velocity of an item `elapsed` seconds after release, in points per second.
    func releasedVelocity(after elapsed: TimeInterval) -> CGVector {
        let ramp = min(max(elapsed / Self.rampDuration, 0), 1)
        return velocity(pointsPerSecond: CGFloat(fallSpeedKHPerSecond * ramp) * kitchenHeight)
    }

    /// Velocity of a bubble that crosses `distance` points in `lifeSec`.
    /// Bubbles drift the same way as gravity, at their own constant speed.
    func bubbleVelocity(crossing distance: CGFloat, lifeSec: TimeInterval) -> CGVector {
        guard lifeSec > 0 else { return .zero }
        return velocity(pointsPerSecond: distance / CGFloat(lifeSec))
    }

    private func velocity(pointsPerSecond speed: CGFloat) -> CGVector {
        let direction = gravity.direction.unitVector
        return CGVector(dx: direction.dx * speed, dy: direction.dy * speed)
    }
}
