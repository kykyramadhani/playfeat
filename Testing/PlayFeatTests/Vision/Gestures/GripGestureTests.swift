//
//  GripGestureTests.swift
//  PlayFeatTests
//  Created by Owen Limantoro on 12/11/26.
//
//  The saved pickup gesture, and which grips need the fingers' shapes.
//

import Testing
import Foundation
@testable import PlayFeat

struct GripGestureTests {

    /// A throwaway store per test, so nothing leaks into the app's settings.
    private func emptyDefaults() throws -> UserDefaults {
        let suite = "GripGestureTests.\(UUID().uuidString)"
        return try #require(UserDefaults(suiteName: suite))
    }

    @Test func nothingSavedMeansPinch() throws {
        #expect(GripGesture.stored(in: try emptyDefaults()) == .pinch)
    }

    @Test func aSavedGripIsReadBack() throws {
        let defaults = try emptyDefaults()
        defaults.set(GripGesture.fPinch.rawValue, forKey: GripGesture.storageKey)

        #expect(GripGesture.stored(in: defaults) == .fPinch)
    }

    /// A grip saved by an older build that has since been removed.
    @Test func aRemovedGripFallsBackToPinch() throws {
        let defaults = try emptyDefaults()
        defaults.set("openPalm", forKey: GripGesture.storageKey)

        #expect(GripGesture.stored(in: defaults) == .pinch)
    }

    @Test func onlyFPinchNeedsFingerShapes() {
        #expect(GripGesture.fPinch.usesFingerShapes)
        #expect(!GripGesture.pinch.usesFingerShapes)
    }
}
