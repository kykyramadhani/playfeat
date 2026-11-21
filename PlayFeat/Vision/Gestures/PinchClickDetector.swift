//
//  PinchClickDetector.swift
//  PlayFeat
//  Created by Owen Limantoro on 20/11/26.
//
//  Turns hands pinching over buttons into button presses, for screens a
//  seated player may be too far away to touch. A press is the moment a
//  pinch starts over a button, so holding a pinch or dragging one onto a
//  button presses nothing. Pure, so it can be tested without a camera.
//

import CoreGraphics

nonisolated struct PinchClickDetector {
    /// One hand as a pointer: where it is on screen and whether it pinches.
    struct Pointer {
        let handID: Int
        let location: CGPoint
        let isPinching: Bool
    }

    /// Whether each hand pinched last frame, by hand ID.
    private var wasPinching: [Int: Bool] = [:]

    /// The index in `targets` of the button pressed this frame, if any.
    /// Only one press counts per frame, since a press usually changes the
    /// screen. A hand seen for the first time already pinching presses
    /// nothing: the pinch has to start in view.
    mutating func press(by pointers: [Pointer], on targets: [CGRect]) -> Int? {
        var pressed: Int?
        for pointer in pointers {
            let startsPinch = pointer.isPinching && wasPinching[pointer.handID] == false
            if startsPinch, pressed == nil {
                pressed = Self.target(at: pointer.location, in: targets)
            }
            wasPinching[pointer.handID] = pointer.isPinching
        }
        let seen = Set(pointers.map(\.handID))
        wasPinching = wasPinching.filter { seen.contains($0.key) }
        return pressed
    }

    /// The button under `point`: the last one listed, which is drawn on top.
    static func target(at point: CGPoint, in targets: [CGRect]) -> Int? {
        targets.lastIndex { $0.contains(point) }
    }
}
