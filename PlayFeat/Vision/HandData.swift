//
//  SwiftUIView.swift
//  GetCooking
//
//  Created by Owen Limantoro on 12/08/26.
//

import SwiftUI

/// One tracked hand, as published to the UI and the scene.
///
/// `id` is stable across frames — see `HandIdentityTracker`. Without that,
/// two-handed play breaks the moment Vision reorders its observations, because
/// each hand would inherit the other's grab.
nonisolated struct HandData: Identifiable, Equatable {
    let id: Int
    /// Palm centre in *normalized Vision space* (origin bottom-left, 0...1).
    var cursorPosition: CGPoint
    /// Where the grip holds things, normalized Vision space. Unlike the cursor
    /// it isn't smoothed, so at the moment of a grab it is where the hand
    /// really is, not where it was a few frames ago.
    var grabPoint: CGPoint
    /// Not grabbing: the selected grip (see `GripGesture`) isn't being made.
    var isOpenHand: Bool
    /// Grabbing: the selected grip is being made. When neither this nor
    /// `isOpenHand` is true, the grip couldn't be read this frame.
    var isClosedFist: Bool
    /// One chain of joints per finger (thumb → little), normalized Vision space.
    var skeleton: [[CGPoint]]
    /// The player's left or right hand, from the body pose; nil until the
    /// body has placed it. Two hands never share a side.
    var side: HandSide? = nil

    /// Every detected joint of this hand as a flat list.
    var recognizedJoints: [CGPoint] { skeleton.flatMap { $0 } }
}
