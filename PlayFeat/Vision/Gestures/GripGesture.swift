//
//  GripGesture.swift
//  PlayFeat
//  Created by Owen Limantoro on 12/11/26.
//
//  The hand pose that picks an ingredient up, chosen in Settings. Read by the
//  frame processor on the camera's queue, so it lives in UserDefaults rather
//  than in a view.
//

import Foundation

nonisolated enum GripGesture: String, CaseIterable, Sendable {
    /// Thumb tip meets index fingertip.
    case pinch
    /// The same pinch, with the middle, ring and little fingers held up: the
    /// "F" sign. Harder to make by accident while reaching around.
    case fPinch

    static let storageKey = "gripGesture"
    static let defaultGesture = Self.pinch

    /// The saved choice. Falls back to the default for anything it doesn't
    /// recognise, such as a grip from an older build that no longer exists.
    static func stored(in defaults: UserDefaults = .standard) -> Self {
        defaults.string(forKey: storageKey).flatMap(Self.init(rawValue:)) ?? defaultGesture
    }

    /// Whether this grip is judged from the fingers' shapes as well as the
    /// pinch. The classifier only measures finger shapes when it is.
    var usesFingerShapes: Bool { self == .fPinch }
}
