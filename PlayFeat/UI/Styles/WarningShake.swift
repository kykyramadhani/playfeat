//
//  WarningShake.swift
//  PlayFeat
//  Created by Owen Limantoro on 20/11/26.
//
//  A quick wiggle and pop that says "hurry": each time `beat` changes the
//  view swings side to side and swells a little, then settles. A marathon
//  round's clock beats once a second in its last seconds, and stops beating
//  (nil) when time runs out, which puts it straight back level.
//

import SwiftUI

extension View {
    /// Wiggles this view each time `beat` changes, unless Reduce Motion is
    /// on. While `beat` is nil the view is drawn level, even mid-wiggle.
    func warningShake(on beat: Int?) -> some View {
        modifier(WarningShake(beat: beat))
    }
}

private struct WarningShake: ViewModifier {
    let beat: Int?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.keyframeAnimator(initialValue: Pose(), trigger: beat) { view, pose in
                // Kept in place rather than removed when the beat stops, so
                // the first beat still wiggles; it is only drawn level.
                let pose = beat == nil ? Pose() : pose
                view
                    .rotationEffect(.degrees(pose.degrees))
                    .scaleEffect(pose.scale)
            } keyframes: { _ in
                KeyframeTrack(\.degrees) {
                    LinearKeyframe(-7, duration: 0.06)
                    LinearKeyframe(7, duration: 0.1)
                    LinearKeyframe(-5, duration: 0.1)
                    LinearKeyframe(4, duration: 0.08)
                    SpringKeyframe(0, duration: 0.16)
                }
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.12, duration: 0.15)
                    SpringKeyframe(1, duration: 0.35)
                }
            }
        }
    }

    struct Pose {
        var degrees: Double = 0
        var scale: CGFloat = 1
    }
}
