//
//  DragMotion.swift
//  PlayFeat
//  Created by kyky on 22/11/26.
//
//  How carried food follows a hand: eased toward the pinch at the same speed
//  whatever the frame rate, and never pulled off screen. Pure maths, so it
//  is tested without a scene.
//

import CoreGraphics
import Foundation

nonisolated enum DragMotion {
    /// Largest frame gap that still eases normally. Past this the scene has
    /// stalled, and closing a huge fraction of the gap in one go would snap a
    /// carried bubble across the screen.
    static let maxEasingDelta: TimeInterval = 0.1

    /// Turns a per-60Hz-frame easing fraction into one for a frame that
    /// actually lasted `delta`.
    ///
    /// `base` is how much of the remaining gap to close in one frame at 60Hz.
    /// An iPad Pro draws at 120, where frames are half as long — closing the
    /// same fraction each time would make a dragged bubble twice as twitchy on
    /// the very device this is tuned on.
    static func easing(base: CGFloat, delta: TimeInterval) -> CGFloat {
        guard base > 0 else { return 0 }
        guard base < 1 else { return 1 }

        // No previous frame to measure against — take the base as given.
        guard delta > 0 else { return base }

        let elapsed = min(delta, maxEasingDelta)
        return CGFloat(1 - pow(1 - Double(base), elapsed * 60))
    }

    /// Pins a point far enough inside the scene that a bubble of `radius`
    /// stays fully on screen.
    ///
    /// The hand itself is not clamped: a hand reaching past the edge of the
    /// camera's view maps to a point outside the scene. It's the food that
    /// must not follow it out, because once it leaves the frame there is no
    /// way to reach it again.
    ///
    /// `max` on the upper bound because a scene narrower than two radii would
    /// otherwise build a reversed range, which traps at runtime.
    static func clamped(_ point: CGPoint, radius: CGFloat, in size: CGSize) -> CGPoint {
        CGPoint(
            x: point.x.clamped(to: radius...max(radius, size.width - radius)),
            y: point.y.clamped(to: radius...max(radius, size.height - radius))
        )
    }
}
